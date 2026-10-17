#include "MediaEngine.h"
#include <QDir>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QProcess>
#include <QStandardPaths>

MediaEngine::MediaEngine(QObject *parent) : QObject(parent) {}
bool MediaEngine::available() const { return true; }
QString MediaEngine::backend() const { return QStringLiteral("native-contract"); }
QString MediaEngine::normalizePath(const QString &path) const {
    if (path.isEmpty()) return {};
    const QUrl url(path);
    return QFileInfo(url.isLocalFile() ? url.toLocalFile() : path).absoluteFilePath();
}
bool MediaEngine::acceptsPath(const QString &path) const {
    const QFileInfo info(normalizePath(path));
    return info.exists() && info.isFile();
}
QVariantMap MediaEngine::capabilities() const {
    const bool probe = !QStandardPaths::findExecutable(QStringLiteral("ffprobe")).isEmpty();
    const bool ffmpeg = !QStandardPaths::findExecutable(QStringLiteral("ffmpeg")).isEmpty();
    return {{QStringLiteral("metadata"), probe}, {QStringLiteral("keyframeIndex"), probe},
            {QStringLiteral("frameRequests"), ffmpeg}, {QStringLiteral("backend"), backend()},
            {QStringLiteral("reason"), probe && ffmpeg ? QStringLiteral("metadata probing and frame extraction available") : QStringLiteral("native media tools are unavailable; optional features disabled")}};
}
static int nextId(int &value) { const int result = value++; if (value <= 0) value = 1; return result; }

int MediaEngine::requestMetadata(const QString &path, int generation) {
    if (m_activeProcess) { m_activeProcess->kill(); m_activeProcess = nullptr; }
    const QString normalized = normalizePath(path);
    if (!acceptsPath(normalized) || QStandardPaths::findExecutable(QStringLiteral("ffprobe")).isEmpty()) return 0;
    const int id = nextId(m_nextRequestId); auto *process = new QProcess(this); m_activeProcess = process;
    connect(process, &QProcess::finished, this, [this, process, id, generation, normalized](int code, QProcess::ExitStatus status) {
        QVariantMap result{{QStringLiteral("ok"), false}};
        if (status == QProcess::NormalExit && code == 0) {
            const auto object = QJsonDocument::fromJson(process->readAllStandardOutput()).object();
            const auto streams = object.value(QStringLiteral("streams")).toArray();
            if (!streams.isEmpty()) { const auto stream = streams.first().toObject(); const auto format = object.value(QStringLiteral("format")).toObject();
                result.insert(QStringLiteral("width"), stream.value(QStringLiteral("width")).toInt()); result.insert(QStringLiteral("height"), stream.value(QStringLiteral("height")).toInt()); result.insert(QStringLiteral("codec"), stream.value(QStringLiteral("codec_name")).toString()); result.insert(QStringLiteral("fps"), stream.value(QStringLiteral("r_frame_rate")).toString()); result.insert(QStringLiteral("duration"), format.value(QStringLiteral("duration")).toString()); result.insert(QStringLiteral("bitrate"), format.value(QStringLiteral("bit_rate")).toString()); result.insert(QStringLiteral("ok"), true); }
        }
        if (m_activeProcess == process) m_activeProcess = nullptr; emit metadataReady(id, generation, normalized, result); process->deleteLater();
    });
    process->start(QStringLiteral("ffprobe"), {QStringLiteral("-v"), QStringLiteral("error"), QStringLiteral("-show_streams"), QStringLiteral("-show_format"), QStringLiteral("-of"), QStringLiteral("json"), normalized}); return id;
}

int MediaEngine::requestKeyframes(const QString &path, int generation) {
    if (m_activeProcess) { m_activeProcess->kill(); m_activeProcess = nullptr; }
    const QString normalized = normalizePath(path);
    if (!acceptsPath(normalized) || QStandardPaths::findExecutable(QStringLiteral("ffprobe")).isEmpty()) return 0;
    const int id = nextId(m_nextRequestId); auto *process = new QProcess(this); m_activeProcess = process;
    connect(process, &QProcess::finished, this, [this, process, id, generation, normalized](int code, QProcess::ExitStatus status) {
        QVariantList timestamps; if (status == QProcess::NormalExit && code == 0) { const auto frames = QJsonDocument::fromJson(process->readAllStandardOutput()).object().value(QStringLiteral("frames")).toArray(); for (const auto &frame : frames) { const auto value = frame.toObject().value(QStringLiteral("best_effort_timestamp_time")); const double seconds = value.isString() ? value.toString().toDouble() : value.toDouble(); if (seconds >= 0.0) timestamps.append(seconds * 1000.0); } }
        if (m_activeProcess == process) m_activeProcess = nullptr; emit keyframesReady(id, generation, normalized, timestamps); process->deleteLater();
    });
    process->start(QStringLiteral("ffprobe"), {QStringLiteral("-v"), QStringLiteral("error"), QStringLiteral("-skip_frame"), QStringLiteral("nokey"), QStringLiteral("-select_streams"), QStringLiteral("v:0"), QStringLiteral("-show_frames"), QStringLiteral("-of"), QStringLiteral("json"), normalized}); return id;
}

int MediaEngine::requestFrame(const QString &path, qint64 timestampMs, int generation, const QString &outputDirectory, int maxWidth) {
    if (m_activeProcess) { m_activeProcess->kill(); m_activeProcess = nullptr; }
    const QString normalized = normalizePath(path); if (!acceptsPath(normalized) || timestampMs < 0 || QStandardPaths::findExecutable(QStringLiteral("ffmpeg")).isEmpty()) return 0; QDir directory(outputDirectory); if (outputDirectory.isEmpty() || !directory.mkpath(QStringLiteral("."))) return 0;
    const int id = nextId(m_nextRequestId); const QString outputPath = directory.filePath(QStringLiteral("frame-%1.png").arg(id)); auto *process = new QProcess(this); m_activeProcess = process;
    connect(process, &QProcess::finished, this, [this, process, id, generation, normalized, timestampMs, outputPath](int code, QProcess::ExitStatus status) { const bool ok = status == QProcess::NormalExit && code == 0 && QFileInfo(outputPath).isFile() && QFileInfo(outputPath).size() > 0; if (m_activeProcess == process) m_activeProcess = nullptr; emit frameReady(id, generation, normalized, timestampMs, outputPath, ok, ok ? QString() : process->errorString()); process->deleteLater(); });
    const QString scale = QStringLiteral("scale='min(%1,iw)':-2:force_original_aspect_ratio=decrease").arg(qBound(160, maxWidth, 3840));
    process->start(QStringLiteral("ffmpeg"), {QStringLiteral("-hide_banner"), QStringLiteral("-loglevel"), QStringLiteral("error"), QStringLiteral("-ss"), QString::number(timestampMs / 1000.0, 'f', 3), QStringLiteral("-i"), normalized, QStringLiteral("-vf"), scale, QStringLiteral("-frames:v"), QStringLiteral("1"), QStringLiteral("-y"), outputPath}); return id;
}

void MediaEngine::cancelMetadata(int requestId) { Q_UNUSED(requestId) if (m_activeProcess) { m_activeProcess->kill(); m_activeProcess = nullptr; } }
