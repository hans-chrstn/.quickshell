#include "CacheDatabase.h"
#include <QFileInfo>
#include <QDir>
#include <QCryptographicHash>
#include <QFile>
#include <QStorageInfo>
#include <QDateTime>
#include <QDirIterator>
#include <QSet>
#include <sqlite3.h>

namespace {
bool hasColumn(sqlite3 *database, const char *name) {
    sqlite3_stmt *statement = nullptr;
    if (sqlite3_prepare_v2(database, "PRAGMA table_info(cache_entries)", -1, &statement, nullptr) != SQLITE_OK)
        return false;
    bool found = false;
    while (sqlite3_step(statement) == SQLITE_ROW) {
        const char *column = reinterpret_cast<const char *>(sqlite3_column_text(statement, 1));
        if (column && qstrcmp(column, name) == 0) {
            found = true;
            break;
        }
    }
    sqlite3_finalize(statement);
    return found;
}

bool ensureColumn(sqlite3 *database, const char *name, const char *definition) {
    if (hasColumn(database, name)) return true;
    const QByteArray sql = QByteArray("ALTER TABLE cache_entries ADD COLUMN ") + name + " " + definition;
    return sqlite3_exec(database, sql.constData(), nullptr, nullptr, nullptr) == SQLITE_OK;
}

bool payloadChecksum(const QString &path, QString *checksum) {
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly)) return false;
    QCryptographicHash hash(QCryptographicHash::Sha256);
    while (!file.atEnd()) {
        const QByteArray chunk = file.read(1024 * 1024);
        if (chunk.isEmpty() && !file.atEnd()) return false;
        hash.addData(chunk);
    }
    *checksum = QString::fromLatin1(hash.result().toHex());
    return true;
}
}

CacheDatabase::CacheDatabase(QObject *parent) : QObject(parent) {}
CacheDatabase::~CacheDatabase() { close(); }
bool CacheDatabase::isOpen() const { return m_database != nullptr; }
bool CacheDatabase::open(const QString &path) {
    close(); if (path.isEmpty()) return false; QFileInfo info(path);
    if (!info.dir().exists() && !info.dir().mkpath(QStringLiteral("."))) return false;
    if (sqlite3_open_v2(path.toUtf8().constData(), &m_database, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, nullptr) != SQLITE_OK) { close(); return false; }
    sqlite3_busy_timeout(m_database, 1000);
    const char *schema = "PRAGMA journal_mode=WAL; PRAGMA synchronous=NORMAL; PRAGMA wal_autocheckpoint=1000; CREATE TABLE IF NOT EXISTS cache_entries (key TEXT PRIMARY KEY, source_hash TEXT NOT NULL, kind TEXT NOT NULL, path TEXT NOT NULL, version INTEGER NOT NULL, size_bytes INTEGER NOT NULL DEFAULT 0, last_used_ms INTEGER NOT NULL DEFAULT 0, protected INTEGER NOT NULL DEFAULT 0, checksum_sha256 TEXT NOT NULL DEFAULT '', generator_version TEXT NOT NULL DEFAULT ''); CREATE TABLE IF NOT EXISTS cache_metadata (key TEXT PRIMARY KEY, source_hash TEXT NOT NULL, payload TEXT NOT NULL, last_used_ms INTEGER NOT NULL DEFAULT 0);";
    if (sqlite3_exec(m_database, schema, nullptr, nullptr, nullptr) != SQLITE_OK) { close(); return false; }
    if (!ensureColumn(m_database, "checksum_sha256", "TEXT NOT NULL DEFAULT ''") ||
        !ensureColumn(m_database, "generator_version", "TEXT NOT NULL DEFAULT ''")) { close(); return false; }
    emit openChanged(); return true;
}
void CacheDatabase::close() { if (!m_database) return; sqlite3_close(m_database); m_database = nullptr; emit openChanged(); }
qint64 CacheDatabase::availableBytes(const QString &path) const {
    const QStorageInfo storage(path);
    return storage.isValid() && storage.isReady() ? storage.bytesAvailable() : -1;
}
bool CacheDatabase::publish(const QString &temporaryPath, const QString &finalPath,
                            const QVariantMap &entry) {
    if (!m_database || temporaryPath.isEmpty() || finalPath.isEmpty()
        || temporaryPath == finalPath)
        return false;
    const QFileInfo temporary(temporaryPath);
    const QFileInfo destination(finalPath);
    if (!temporary.isFile() || destination.exists()
        || temporary.absolutePath() != destination.absolutePath())
        return false;
    if (!QFile::rename(temporary.filePath(), destination.filePath()))
        return false;
    QVariantMap published = entry;
    published.insert(QStringLiteral("path"), destination.filePath());
    if (upsert(published)) return true;
    QFile::remove(destination.filePath());
    return false;
}
bool CacheDatabase::upsert(const QVariantMap &entry) {
    if (!m_database) return false;
    const QString keyValue = entry.value(QStringLiteral("key")).toString().trimmed();
    const QString pathValue = entry.value(QStringLiteral("path")).toString();
    if (keyValue.isEmpty() || pathValue.isEmpty()) return false;
    const QFileInfo payload(pathValue);
    const qlonglong expectedSize = entry.value(QStringLiteral("sizeBytes")).toLongLong();
    if (!payload.isFile() || (expectedSize > 0 && payload.size() != expectedSize)) return false;
    const QString expectedChecksum = entry.value(QStringLiteral("checksumSha256")).toString().trimmed().toLower();
    if (!expectedChecksum.isEmpty()) {
        QString actualChecksum;
        if (!payloadChecksum(payload.filePath(), &actualChecksum) || actualChecksum != expectedChecksum) return false;
    }
    sqlite3_stmt *statement = nullptr;
    const char *sql = "INSERT INTO cache_entries(key,source_hash,kind,path,version,size_bytes,last_used_ms,protected,checksum_sha256,generator_version) VALUES(?,?,?,?,?,?,?,?,?,?) ON CONFLICT(key) DO UPDATE SET source_hash=excluded.source_hash,kind=excluded.kind,path=excluded.path,version=excluded.version,size_bytes=excluded.size_bytes,last_used_ms=excluded.last_used_ms,protected=excluded.protected,checksum_sha256=excluded.checksum_sha256,generator_version=excluded.generator_version;";
    if (sqlite3_prepare_v2(m_database, sql, -1, &statement, nullptr) != SQLITE_OK) return false;
    const QByteArray key = keyValue.toUtf8(); const QByteArray hash = entry.value(QStringLiteral("sourceHash")).toString().toUtf8(); const QByteArray kind = entry.value(QStringLiteral("kind")).toString().toUtf8(); const QByteArray path = pathValue.toUtf8();
    const QByteArray checksum = expectedChecksum.toUtf8(); const QByteArray generator = entry.value(QStringLiteral("generatorVersion")).toString().toUtf8();
    sqlite3_bind_text(statement, 1, key.constData(), -1, SQLITE_TRANSIENT); sqlite3_bind_text(statement, 2, hash.constData(), -1, SQLITE_TRANSIENT); sqlite3_bind_text(statement, 3, kind.constData(), -1, SQLITE_TRANSIENT); sqlite3_bind_text(statement, 4, path.constData(), -1, SQLITE_TRANSIENT); sqlite3_bind_int(statement, 5, entry.value(QStringLiteral("version")).toInt()); sqlite3_bind_int64(statement, 6, entry.value(QStringLiteral("sizeBytes")).toLongLong()); sqlite3_bind_int64(statement, 7, entry.value(QStringLiteral("lastUsedMs")).toLongLong()); sqlite3_bind_int(statement, 8, entry.value(QStringLiteral("protected")).toBool() ? 1 : 0); sqlite3_bind_text(statement, 9, checksum.constData(), -1, SQLITE_TRANSIENT); sqlite3_bind_text(statement, 10, generator.constData(), -1, SQLITE_TRANSIENT);
    const bool success = sqlite3_step(statement) == SQLITE_DONE; sqlite3_finalize(statement); return success;
}
bool CacheDatabase::touch(const QString &key, qint64 timestampMs) {
    if (!m_database || key.trimmed().isEmpty()) return false;
    sqlite3_stmt *statement = nullptr;
    if (sqlite3_prepare_v2(m_database,
                           "UPDATE cache_entries SET last_used_ms=? WHERE key=?",
                           -1, &statement, nullptr) != SQLITE_OK)
        return false;
    const QByteArray bytes = key.toUtf8();
    sqlite3_bind_int64(statement, 1, timestampMs > 0
        ? timestampMs : QDateTime::currentMSecsSinceEpoch());
    sqlite3_bind_text(statement, 2, bytes.constData(), -1, SQLITE_TRANSIENT);
    const bool success = sqlite3_step(statement) == SQLITE_DONE
        && sqlite3_changes(m_database) > 0;
    sqlite3_finalize(statement);
    return success;
}
bool CacheDatabase::setProtected(const QString &key, bool protectedEntry) {
    if (!m_database || key.trimmed().isEmpty()) return false;
    sqlite3_stmt *statement = nullptr;
    if (sqlite3_prepare_v2(m_database,
                           "UPDATE cache_entries SET protected=? WHERE key=?",
                           -1, &statement, nullptr) != SQLITE_OK)
        return false;
    const QByteArray bytes = key.toUtf8();
    sqlite3_bind_int(statement, 1, protectedEntry ? 1 : 0);
    sqlite3_bind_text(statement, 2, bytes.constData(), -1, SQLITE_TRANSIENT);
    const bool success = sqlite3_step(statement) == SQLITE_DONE
        && sqlite3_changes(m_database) > 0;
    sqlite3_finalize(statement);
    return success;
}
QVariantList CacheDatabase::lruCandidates(int maximum) const {
    QVariantList result;
    if (!m_database || maximum <= 0) return result;
    sqlite3_stmt *statement = nullptr;
    if (sqlite3_prepare_v2(m_database,
                           "SELECT key,kind,path,size_bytes,last_used_ms,version,generator_version FROM cache_entries WHERE protected=0 ORDER BY last_used_ms ASC, key ASC LIMIT ?",
                           -1, &statement, nullptr) != SQLITE_OK)
        return result;
    sqlite3_bind_int(statement, 1, qMin(maximum, 1024));
    while (sqlite3_step(statement) == SQLITE_ROW) {
        QVariantMap entry;
        entry.insert(QStringLiteral("key"), QString::fromUtf8(reinterpret_cast<const char *>(sqlite3_column_text(statement, 0))));
        entry.insert(QStringLiteral("kind"), QString::fromUtf8(reinterpret_cast<const char *>(sqlite3_column_text(statement, 1))));
        entry.insert(QStringLiteral("path"), QString::fromUtf8(reinterpret_cast<const char *>(sqlite3_column_text(statement, 2))));
        entry.insert(QStringLiteral("sizeBytes"), static_cast<qlonglong>(sqlite3_column_int64(statement, 3)));
        entry.insert(QStringLiteral("lastUsedMs"), static_cast<qlonglong>(sqlite3_column_int64(statement, 4)));
        entry.insert(QStringLiteral("version"), sqlite3_column_int(statement, 5));
        entry.insert(QStringLiteral("generatorVersion"), QString::fromUtf8(reinterpret_cast<const char *>(sqlite3_column_text(statement, 6))));
        result.append(entry);
    }
    sqlite3_finalize(statement);
    return result;
}
QVariantMap CacheDatabase::lookup(const QString &key) const {
    if (!m_database || key.isEmpty()) return {}; sqlite3_stmt *statement = nullptr;
    if (sqlite3_prepare_v2(m_database, "SELECT source_hash,kind,path,version,size_bytes,last_used_ms,protected,checksum_sha256,generator_version FROM cache_entries WHERE key=?", -1, &statement, nullptr) != SQLITE_OK) return {};
    const QByteArray bytes = key.toUtf8(); sqlite3_bind_text(statement, 1, bytes.constData(), -1, SQLITE_TRANSIENT); QVariantMap result;
    if (sqlite3_step(statement) == SQLITE_ROW) { const QString path = QString::fromUtf8(reinterpret_cast<const char *>(sqlite3_column_text(statement, 2))); const qlonglong expectedSize = sqlite3_column_int64(statement, 4); const QString expectedChecksum = QString::fromUtf8(reinterpret_cast<const char *>(sqlite3_column_text(statement, 7))); const QFileInfo file(path); bool integrityMatches = file.isFile() && (expectedSize <= 0 || file.size() == expectedSize); if (integrityMatches && !expectedChecksum.isEmpty()) { QString actualChecksum; integrityMatches = payloadChecksum(path, &actualChecksum) && actualChecksum == expectedChecksum; } result.insert(QStringLiteral("key"), key); result.insert(QStringLiteral("sourceHash"), QString::fromUtf8(reinterpret_cast<const char *>(sqlite3_column_text(statement, 0)))); result.insert(QStringLiteral("kind"), QString::fromUtf8(reinterpret_cast<const char *>(sqlite3_column_text(statement, 1)))); result.insert(QStringLiteral("path"), path); result.insert(QStringLiteral("version"), sqlite3_column_int(statement, 3)); result.insert(QStringLiteral("sizeBytes"), expectedSize); result.insert(QStringLiteral("lastUsedMs"), static_cast<qlonglong>(sqlite3_column_int64(statement, 5))); result.insert(QStringLiteral("protected"), sqlite3_column_int(statement, 6) != 0); result.insert(QStringLiteral("checksumSha256"), expectedChecksum); result.insert(QStringLiteral("generatorVersion"), QString::fromUtf8(reinterpret_cast<const char *>(sqlite3_column_text(statement, 8)))); result.insert(QStringLiteral("present"), file.isFile()); result.insert(QStringLiteral("sizeMatches"), file.isFile() && (expectedSize <= 0 || file.size() == expectedSize)); result.insert(QStringLiteral("integrityMatches"), integrityMatches); }
    sqlite3_finalize(statement); return result;
}

bool CacheDatabase::remove(const QString &key) {
    if (!m_database || key.isEmpty()) return false;
    sqlite3_stmt *statement = nullptr;
    if (sqlite3_prepare_v2(m_database, "DELETE FROM cache_entries WHERE key=?", -1, &statement, nullptr) != SQLITE_OK) return false;
    const QByteArray bytes = key.toUtf8(); sqlite3_bind_text(statement, 1, bytes.constData(), -1, SQLITE_TRANSIENT);
    const bool success = sqlite3_step(statement) == SQLITE_DONE; sqlite3_finalize(statement); return success;
}

bool CacheDatabase::upsertMetadata(const QString &key, const QString &sourceHash,
                                   const QString &payload, qint64 lastUsedMs) {
    if (!m_database || key.isEmpty() || sourceHash.isEmpty() || payload.isEmpty())
        return false;
    sqlite3_stmt *statement = nullptr;
    if (sqlite3_prepare_v2(m_database,
            "INSERT INTO cache_metadata(key,source_hash,payload,last_used_ms) VALUES(?,?,?,?) ON CONFLICT(key) DO UPDATE SET source_hash=excluded.source_hash,payload=excluded.payload,last_used_ms=excluded.last_used_ms",
            -1, &statement, nullptr) != SQLITE_OK)
        return false;
    sqlite3_bind_text(statement, 1, key.toUtf8().constData(), -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(statement, 2, sourceHash.toUtf8().constData(), -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(statement, 3, payload.toUtf8().constData(), -1, SQLITE_TRANSIENT);
    sqlite3_bind_int64(statement, 4, lastUsedMs);
    const bool ok = sqlite3_step(statement) == SQLITE_DONE;
    sqlite3_finalize(statement);
    return ok;
}

QVariantMap CacheDatabase::metadata(const QString &key) const {
    QVariantMap result;
    if (!m_database || key.isEmpty()) return result;
    sqlite3_stmt *statement = nullptr;
    if (sqlite3_prepare_v2(m_database,
            "SELECT source_hash,payload,last_used_ms FROM cache_metadata WHERE key=?",
            -1, &statement, nullptr) != SQLITE_OK)
        return result;
    sqlite3_bind_text(statement, 1, key.toUtf8().constData(), -1, SQLITE_TRANSIENT);
    if (sqlite3_step(statement) == SQLITE_ROW) {
        result.insert(QStringLiteral("found"), true);
        result.insert(QStringLiteral("sourceHash"), QString::fromUtf8(reinterpret_cast<const char *>(sqlite3_column_text(statement, 0))));
        result.insert(QStringLiteral("payload"), QString::fromUtf8(reinterpret_cast<const char *>(sqlite3_column_text(statement, 1))));
        result.insert(QStringLiteral("lastUsedMs"), static_cast<qlonglong>(sqlite3_column_int64(statement, 2)));
    }
    sqlite3_finalize(statement);
    return result;
}

bool CacheDatabase::removeMetadata(const QString &key) {
    if (!m_database || key.isEmpty()) return false;
    sqlite3_stmt *statement = nullptr;
    if (sqlite3_prepare_v2(m_database, "DELETE FROM cache_metadata WHERE key=?", -1,
                           &statement, nullptr) != SQLITE_OK)
        return false;
    sqlite3_bind_text(statement, 1, key.toUtf8().constData(), -1, SQLITE_TRANSIENT);
    const bool ok = sqlite3_step(statement) == SQLITE_DONE;
    sqlite3_finalize(statement);
    return ok;
}

QVariantList CacheDatabase::staleKeys() const {
    QVariantList keys;
    if (!m_database) return keys;
    sqlite3_stmt *statement = nullptr;
    if (sqlite3_prepare_v2(m_database, "SELECT key,path,size_bytes FROM cache_entries", -1, &statement, nullptr) != SQLITE_OK) return keys;
    while (sqlite3_step(statement) == SQLITE_ROW) {
        const QString key = QString::fromUtf8(reinterpret_cast<const char *>(sqlite3_column_text(statement, 0)));
        const QFileInfo file(QString::fromUtf8(reinterpret_cast<const char *>(sqlite3_column_text(statement, 1))));
        const qlonglong expected = sqlite3_column_int64(statement, 2);
        if (!file.isFile() || (expected > 0 && file.size() != expected)) keys.append(key);
    }
    sqlite3_finalize(statement);
    return keys;
}

QVariantList CacheDatabase::integrityStaleKeys(int maximum) const {
    QVariantList keys;
    if (!m_database || maximum <= 0) return keys;
    sqlite3_stmt *statement = nullptr;
    if (sqlite3_prepare_v2(m_database,
                           "SELECT key,path,size_bytes,checksum_sha256 FROM cache_entries WHERE checksum_sha256<>'' ORDER BY last_used_ms ASC, key ASC LIMIT ?",
                           -1, &statement, nullptr) != SQLITE_OK)
        return keys;
    sqlite3_bind_int(statement, 1, qMin(maximum, 256));
    while (sqlite3_step(statement) == SQLITE_ROW) {
        const QString key = QString::fromUtf8(reinterpret_cast<const char *>(sqlite3_column_text(statement, 0)));
        const QString path = QString::fromUtf8(reinterpret_cast<const char *>(sqlite3_column_text(statement, 1)));
        const qlonglong expectedSize = sqlite3_column_int64(statement, 2);
        const QString expectedChecksum = QString::fromUtf8(reinterpret_cast<const char *>(sqlite3_column_text(statement, 3)));
        const QFileInfo file(path);
        QString actualChecksum;
        if (!file.isFile() || (expectedSize > 0 && file.size() != expectedSize)
            || !payloadChecksum(path, &actualChecksum)
            || actualChecksum != expectedChecksum)
            keys.append(key);
    }
    sqlite3_finalize(statement);
    return keys;
}

QVariantList CacheDatabase::orphanPaths(const QString &rootPath) const {
    QVariantList paths;
    if (!m_database || rootPath.isEmpty()) return paths;
    QSet<QString> indexed;
    sqlite3_stmt *statement = nullptr;
    if (sqlite3_prepare_v2(m_database, "SELECT path FROM cache_entries", -1,
                           &statement, nullptr) != SQLITE_OK)
        return paths;
    while (sqlite3_step(statement) == SQLITE_ROW) {
        const char *value = reinterpret_cast<const char *>(sqlite3_column_text(statement, 0));
        if (value) indexed.insert(QFileInfo(QString::fromUtf8(value)).absoluteFilePath());
    }
    sqlite3_finalize(statement);

    QDirIterator iterator(rootPath, QDir::Files, QDirIterator::Subdirectories);
    while (iterator.hasNext()) {
        const QFileInfo file(iterator.next());
        if (file.isSymLink()) continue;
        const QString name = file.fileName();
        if (name == QFileInfo(QStringLiteral("cache-index.sqlite")).fileName()
            || name.endsWith(QStringLiteral("-wal"))
            || name.endsWith(QStringLiteral("-shm")))
            continue;
        const QString path = file.absoluteFilePath();
        if (!indexed.contains(path)) paths.append(path);
    }
    return paths;
}

bool CacheDatabase::removeOrphan(const QString &rootPath, const QString &path) {
    if (!m_database || rootPath.isEmpty() || path.isEmpty()) return false;
    const QString root = QDir::cleanPath(QFileInfo(rootPath).absoluteFilePath());
    const QString candidate = QDir::cleanPath(QFileInfo(path).absoluteFilePath());
    if (root == QStringLiteral("/") || candidate == root
        || !candidate.startsWith(root + QLatin1Char('/')))
        return false;
    const QFileInfo file(candidate);
    if (!file.isFile() || file.isSymLink()) return false;
    const QString name = file.fileName();
    if (name == QStringLiteral("cache-index.sqlite")
        || name.endsWith(QStringLiteral("-wal"))
        || name.endsWith(QStringLiteral("-shm")))
        return false;
    sqlite3_stmt *statement = nullptr;
    if (sqlite3_prepare_v2(m_database, "SELECT 1 FROM cache_entries WHERE path=? LIMIT 1",
                           -1, &statement, nullptr) != SQLITE_OK)
        return false;
    const QByteArray bytes = candidate.toUtf8();
    sqlite3_bind_text(statement, 1, bytes.constData(), -1, SQLITE_TRANSIENT);
    const bool indexed = sqlite3_step(statement) == SQLITE_ROW;
    sqlite3_finalize(statement);
    return !indexed && QFile::remove(candidate);
}
