#pragma once

#include <QObject>
#include <QUrl>
#include <QVariantMap>
#include <QStringList>
#include <QtQml/qqmlregistration.h>

class QProcess;

class MediaEngine final : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_PROPERTY(bool available READ available CONSTANT)
    Q_PROPERTY(QString backend READ backend CONSTANT)

public:
    explicit MediaEngine(QObject *parent = nullptr);

    bool available() const;
    QString backend() const;

    Q_INVOKABLE QString normalizePath(const QString &path) const;
    Q_INVOKABLE bool acceptsPath(const QString &path) const;
    Q_INVOKABLE QVariantMap capabilities() const;
    Q_INVOKABLE int requestMetadata(const QString &path, int generation);
    Q_INVOKABLE int requestKeyframes(const QString &path, int generation);
    Q_INVOKABLE int requestFrame(const QString &path, qint64 timestampMs,
                                 int generation, const QString &outputDirectory,
                                 int maxWidth = 960);
    Q_INVOKABLE void cancelMetadata(int requestId);

signals:
    void metadataReady(int requestId, int generation, const QString &path,
                       const QVariantMap &metadata);
    void keyframesReady(int requestId, int generation, const QString &path,
                        const QVariantList &timestampsMs);
    void frameReady(int requestId, int generation, const QString &path,
                    qint64 timestampMs, const QString &outputPath, bool ok,
                    const QString &error);

private:
    QProcess *m_activeProcess = nullptr;
    int m_nextRequestId = 1;
};
