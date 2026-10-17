pragma Singleton
import QtQuick
import Quickshell
import Cache

QtObject {
    id: root

    readonly property string databasePath: Quickshell.cachePath("cache-index.sqlite")
    readonly property bool ready: CacheDatabase.ready
    readonly property real minimumHeadroomBytes: 256 * 1024 * 1024
    property string error: ""
    property var lastReconciliation: ({
            attempted: false,
            removed: 0,
            atMs: 0
        })
    property var lastRecovery: ({
            attempted: false,
            rootPath: "",
            staleCount: 0,
            orphanCount: 0,
            atMs: 0
        })

    function ensureOpen() {
        if (CacheDatabase.ready)
            return true
        const opened = CacheDatabase.open(root.databasePath)
        if (!opened)
            root.error = "Cache index could not be opened"
        else
            root.error = ""
        return opened
    }

    function hasHeadroom(path, additionalBytes, reserveBytes) {
        const available = CacheDatabase.availableBytes(String(path || root.databasePath))
        const required = Math.max(0, Number(additionalBytes || 0))
            + Math.max(0, Number(reserveBytes ?? root.minimumHeadroomBytes))
        return available >= 0 && available >= required
    }

    function registerArtifact(entry) {
        if (!root.ensureOpen())
            return false
        const source = entry || ({})
        return CacheDatabase.upsert({
            key: String(source.key || ""),
            sourceHash: String(source.sourceHash || ""),
            kind: String(source.kind || ""),
            path: String(source.path || ""),
            checksumSha256: String(source.checksumSha256 || ""),
            generatorVersion: String(source.generatorVersion || ""),
            version: Number(source.version || 1),
            sizeBytes: Number(source.sizeBytes || 0),
            lastUsedMs: Number(source.lastUsedMs || Date.now()),
            protected: source.protected === true
        })
    }

    function publishArtifact(temporaryPath, finalPath, entry) {
        if (!root.ensureOpen())
            return false
        return CacheDatabase.publish(String(temporaryPath || ""),
            String(finalPath || ""), entry || ({}))
    }

    function artifactFor(key) {
        if (!root.ensureOpen())
            return ({})
        return CacheDatabase.lookup(String(key || ""))
    }

    function touchArtifact(key, timestampMs) {
        if (!root.ensureOpen())
            return false
        return CacheDatabase.touch(String(key || ""),
            Number(timestampMs || Date.now()))
    }

    function setArtifactProtected(key, protectedEntry) {
        if (!root.ensureOpen())
            return false
        return CacheDatabase.setProtected(String(key || ""),
            protectedEntry === true)
    }

    function lruCandidates(maximum) {
        if (!root.ensureOpen())
            return []
        return CacheDatabase.lruCandidates(Math.max(0, Number(maximum || 0)))
    }

    function artifactExists(key) {
        const entry = root.artifactFor(key)
        return entry.present === true && entry.sizeMatches !== false && entry.integrityMatches !== false
    }

    function artifactValid(key, generatorVersion) {
        const entry = root.artifactFor(key)
        if (entry.present !== true || entry.sizeMatches === false
                || entry.integrityMatches === false)
            return false
        const expected = String(generatorVersion || "")
        return expected.length === 0
            || String(entry.generatorVersion || "") === expected
    }

    function removeArtifact(key) {
        if (!root.ensureOpen())
            return false
        return CacheDatabase.remove(String(key || ""))
    }

    function storeMetadata(key, sourceHash, payload, lastUsedMs) {
        if (!root.ensureOpen())
            return false
        return CacheDatabase.upsertMetadata(String(key || ""),
            String(sourceHash || ""), String(payload || ""),
            Number(lastUsedMs || Date.now()))
    }

    function metadataFor(key, sourceHash) {
        if (!root.ensureOpen())
            return ({})
        const result = CacheDatabase.metadata(String(key || ""))
        if (result.found !== true
                || (sourceHash && String(result.sourceHash || "") !== sourceHash))
            return ({})
        return result
    }

    function removeMetadata(key) {
        if (!root.ensureOpen())
            return false
        return CacheDatabase.removeMetadata(String(key || ""))
    }

    function staleArtifactKeys() {
        if (!root.ensureOpen())
            return []
        return CacheDatabase.staleKeys()
    }

    function integrityStaleArtifactKeys(maximum) {
        if (!root.ensureOpen())
            return []
        return CacheDatabase.integrityStaleKeys(Math.max(0,
            Number(maximum || 0)))
    }

    function orphanArtifactPaths(rootPath) {
        if (!root.ensureOpen())
            return []
        return CacheDatabase.orphanPaths(String(rootPath || ""))
    }

    function removeOrphanArtifact(rootPath, path) {
        if (!root.ensureOpen())
            return false
        return CacheDatabase.removeOrphan(String(rootPath || ""),
            String(path || ""))
    }

    function pruneStaleIndexEntries() {
        const stale = root.staleArtifactKeys()
        let removed = 0
        for (const key of stale) {
            if (CacheDatabase.remove(String(key || "")))
                removed += 1
        }
        root.lastReconciliation = ({
                attempted: true,
                inspected: stale.length,
                removed: removed,
                atMs: Date.now()
            })
        return removed
    }

    function snapshot() {
        const stale = root.staleArtifactKeys()
        return ({
                ready: root.ready,
                databasePath: root.databasePath,
                staleCount: stale.length,
                lastReconciliation: Object.assign({}, root.lastReconciliation),
                lastRecovery: Object.assign({}, root.lastRecovery),
                minimumHeadroomBytes: root.minimumHeadroomBytes
            })
    }

    function recoverNamespace(rootPath) {
        if (!root.ensureOpen())
            return ({ accepted: false, staleCount: 0, orphanCount: 0 })
        const normalized = String(rootPath || "")
        const stale = root.staleArtifactKeys()
        const orphans = CacheDatabase.orphanPaths(normalized)
        root.lastRecovery = ({
                attempted: true,
                rootPath: normalized,
                staleCount: stale.length,
                orphanCount: orphans.length,
                atMs: Date.now()
            })
        return ({ accepted: true, staleCount: stale.length,
            orphanCount: orphans.length })
    }
}
