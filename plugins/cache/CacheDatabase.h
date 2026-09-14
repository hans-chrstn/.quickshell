#pragma once
#include <QObject>
#include <QVariantMap>
#include <QtQml/qqmlregistration.h>
struct sqlite3;
class CacheDatabase final : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_PROPERTY(bool ready READ isOpen NOTIFY openChanged)
public:
    explicit CacheDatabase(QObject *parent = nullptr);
    ~CacheDatabase() override;
    bool isOpen() const;
    Q_INVOKABLE bool open(const QString &path);
    Q_INVOKABLE void close();
    Q_INVOKABLE qint64 availableBytes(const QString &path) const;
    Q_INVOKABLE bool publish(const QString &temporaryPath, const QString &finalPath,
                             const QVariantMap &entry);
    Q_INVOKABLE bool upsert(const QVariantMap &entry);
    Q_INVOKABLE bool touch(const QString &key, qint64 timestampMs);
    Q_INVOKABLE bool setProtected(const QString &key, bool protectedEntry);
    Q_INVOKABLE QVariantList lruCandidates(int maximum) const;
    Q_INVOKABLE QVariantMap lookup(const QString &key) const;
    Q_INVOKABLE bool remove(const QString &key);
    Q_INVOKABLE bool upsertMetadata(const QString &key, const QString &sourceHash,
                                    const QString &payload, qint64 lastUsedMs);
    Q_INVOKABLE QVariantMap metadata(const QString &key) const;
    Q_INVOKABLE bool removeMetadata(const QString &key);
    Q_INVOKABLE QVariantList staleKeys() const;
    Q_INVOKABLE QVariantList integrityStaleKeys(int maximum) const;
    Q_INVOKABLE QVariantList orphanPaths(const QString &rootPath) const;
    Q_INVOKABLE bool removeOrphan(const QString &rootPath, const QString &path);
signals:
    void openChanged();
private:
    sqlite3 *m_database = nullptr;
};
