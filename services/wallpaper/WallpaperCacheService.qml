pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services.wallpaper

Singleton {
    id: root

    readonly property string posterDirectory:
        Quickshell.cachePath("wallpaper-posters")
    readonly property string optimizedDirectory:
        Quickshell.cachePath("wallpaper-optimized")
    readonly property double posterBudgetBytes: 64 * 1024 * 1024
    readonly property double optimizedBudgetBytes: 2 * 1024 * 1024 * 1024
    readonly property double posterMaximumAgeMs: 60 * 24 * 60 * 60 * 1000
    readonly property double optimizedMaximumAgeMs:
        90 * 24 * 60 * 60 * 1000

    property bool scanning: false
    property double scannedAt: 0
    property string error: ""
    property var entries: []
    property var cleanupPlan: emptyPlan()
    property bool cleaning: false
    property string cleanupState: "idle"
    property string cleanupError: ""
    property var cleanupQueue: []
    property var activeCleanupEntry: ({})
    property int deletedCount: 0
    property int skippedCount: 0
    property double reclaimedBytes: 0
    property bool automaticPending: false
    property string cleanupCause: "manual"

    readonly property var posterEntries:
        entries.filter(entry => entry.kind === "poster")
    readonly property var optimizedEntries:
        entries.filter(entry => entry.kind === "optimized")
    readonly property double posterBytes:
        posterEntries.reduce((total, entry) => total + entry.size, 0)
    readonly property double optimizedBytes:
        optimizedEntries.reduce((total, entry) => total + entry.size, 0)
    readonly property double totalBytes: posterBytes + optimizedBytes

    function emptyPlan() {
        return {
            generatedAt: 0,
            dryRun: true,
            deleteCount: 0,
            reclaimBytes: 0,
            protectedCount: 0,
            posters: { deleteCount: 0, reclaimBytes: 0,
                projectedBytes: 0, budgetBytes: posterBudgetBytes,
                blockedBytes: 0 },
            optimized: { deleteCount: 0, reclaimBytes: 0,
                projectedBytes: 0, budgetBytes: optimizedBudgetBytes,
                blockedBytes: 0 },
            entries: []
        }
    }

    function addProtection(result, path, reason) {
        const normalized = String(path || "")
        if (normalized.length === 0) return
        const reasons = result[normalized] || []
        if (reasons.indexOf(reason) < 0)
            reasons.push(reason)
        result[normalized] = reasons
    }

    function protectedPaths() {
        const result = ({})
        addProtection(result, WallpaperAssignmentService.globalWallpaper,
            "global-assignment")
        const assignments = WallpaperAssignmentService.screenWallpapers
        for (const screenName in assignments)
            addProtection(result, assignments[screenName],
                "screen-assignment:" + screenName)

        const renderers = WallpaperRenderService.snapshot()
        for (const screenName in renderers)
            addProtection(result, renderers[screenName].path,
                "active-renderer:" + screenName)

        addProtection(result, WallpaperOptimizationService.activeOutput,
            "optimization-output")
        addProtection(result,
            WallpaperOptimizationService.activeTemporaryOutput,
            "optimization-temporary")

        const posters = WallpaperPosterService.records
        for (const sourcePath in posters) {
            addProtection(result, posters[sourcePath].posterPath,
                "poster-record")
            addProtection(result, posters[sourcePath].pendingPosterPath,
                "poster-pending")
        }
        addProtection(result, WallpaperPosterService.activeItem?.posterPath,
            "poster-worker")
        for (const item of WallpaperPosterService.queue)
            addProtection(result, item.posterPath, "poster-queue")
        return result
    }

    function planKind(kind, sourceEntries, budgetBytes, maximumAgeMs,
            protections) {
        const now = Date.now()
        const oldestFirst = sourceEntries.slice().sort((a, b) =>
            a.accessedAt - b.accessedAt || a.path.localeCompare(b.path))
        const selected = []
        const selectedPaths = ({})
        let projectedBytes = sourceEntries.reduce(
            (total, entry) => total + entry.size, 0)
        let protectedBytes = 0

        for (const entry of oldestFirst) {
            if (protections[entry.path]) {
                protectedBytes += entry.size
                continue
            }
            if (entry.accessedAt > 0
                    && now - entry.accessedAt >= maximumAgeMs) {
                selected.push(Object.assign({}, entry, {
                    reason: "stale",
                    protected: false,
                    protectionReasons: []
                }))
                selectedPaths[entry.path] = true
                projectedBytes -= entry.size
            }
        }

        if (projectedBytes > budgetBytes) {
            for (const entry of oldestFirst) {
                if (projectedBytes <= budgetBytes) break
                if (protections[entry.path] || selectedPaths[entry.path])
                    continue
                selected.push(Object.assign({}, entry, {
                    reason: "over-budget",
                    protected: false,
                    protectionReasons: []
                }))
                selectedPaths[entry.path] = true
                projectedBytes -= entry.size
            }
        }

        const reclaimBytes = selected.reduce(
            (total, entry) => total + entry.size, 0)
        return {
            kind: kind,
            deleteCount: selected.length,
            reclaimBytes: reclaimBytes,
            projectedBytes: projectedBytes,
            budgetBytes: budgetBytes,
            protectedBytes: protectedBytes,
            blockedBytes: Math.max(0, projectedBytes - budgetBytes),
            entries: selected
        }
    }

    function buildPlan() {
        const protections = protectedPaths()
        const posters = planKind("poster", posterEntries,
            posterBudgetBytes, posterMaximumAgeMs, protections)
        const optimized = planKind("optimized", optimizedEntries,
            optimizedBudgetBytes, optimizedMaximumAgeMs, protections)
        let protectedCount = 0
        for (const entry of entries) {
            if (protections[entry.path]) protectedCount += 1
        }
        cleanupPlan = {
            generatedAt: Date.now(),
            dryRun: true,
            deleteCount: posters.deleteCount + optimized.deleteCount,
            reclaimBytes: posters.reclaimBytes + optimized.reclaimBytes,
            protectedCount: protectedCount,
            posters: posters,
            optimized: optimized,
            entries: posters.entries.concat(optimized.entries)
        }
        return cleanupPlan
    }

    function scan() {
        if (scanning || cleaning)
            return false
        scanning = true
        error = ""
        scanProcess.output = ""
        scanProcess.command = [
            "find", posterDirectory, optimizedDirectory,
            "-maxdepth", "1", "-type", "f",
            "-printf", "%p\\t%s\\t%A@\\n"
        ]
        scanProcess.running = true
        return true
    }

    function cachePathAllowed(path) {
        const value = String(path || "")
        return value.startsWith(posterDirectory + "/")
            || value.startsWith(optimizedDirectory + "/")
    }

    function executeCleanup() {
        if (scanning || cleaning)
            return false
        const plan = buildPlan()
        cleanupCause = "manual"
        cleanupError = ""
        deletedCount = 0
        skippedCount = 0
        reclaimedBytes = 0
        if (plan.entries.length === 0) {
            cleanupState = "ready"
            return true
        }
        cleanupQueue = plan.entries.slice()
        cleaning = true
        cleanupState = "cleaning"
        startCleanupEntry()
        return true
    }

    function requestAutomaticCleanup() {
        automaticPending = true
        if (cleaning || scanning)
            return true
        return scan()
    }

    function startCleanupEntry() {
        if (!cleaning) return
        if (cleanupQueue.length === 0) {
            finishCleanup()
            return
        }
        const remaining = cleanupQueue.slice()
        const entry = remaining.shift()
        cleanupQueue = remaining
        if (!cachePathAllowed(entry.path)
                || protectedPaths()[entry.path]) {
            skippedCount += 1
            Qt.callLater(startCleanupEntry)
            return
        }
        activeCleanupEntry = entry
        verifyProcess.output = ""
        verifyProcess.command = ["stat", "--printf=%s|%X", "--", entry.path]
        verifyProcess.running = true
    }

    function finishCleanup() {
        cleaning = false
        activeCleanupEntry = ({})
        cleanupQueue = []
        cleanupState = "ready"
        scan()
    }

    function parse(output) {
        const result = []
        for (const line of String(output || "").split("\n")) {
            if (line.length === 0) continue
            const fields = line.split("\t")
            if (fields.length < 3) continue
            const path = fields[0]
            const size = Math.max(0, Number(fields[1]) || 0)
            const accessedAt = Math.max(0, Number(fields[2]) || 0) * 1000
            const kind = path.startsWith(optimizedDirectory + "/")
                ? "optimized" : path.startsWith(posterDirectory + "/")
                    ? "poster" : "unknown"
            if (kind === "unknown") continue
            result.push({
                path: path,
                kind: kind,
                size: size,
                accessedAt: accessedAt
            })
        }
        result.sort((a, b) => b.accessedAt - a.accessedAt
            || a.path.localeCompare(b.path))
        return result
    }

    function snapshot() {
        return {
            scanning: scanning,
            scannedAt: scannedAt,
            error: error,
            totalBytes: totalBytes,
            posters: { count: posterEntries.length, bytes: posterBytes },
            optimized: {
                count: optimizedEntries.length,
                bytes: optimizedBytes
            },
            entries: entries,
            cleanupPlan: cleanupPlan,
            cleanup: {
                state: cleanupState,
                cleaning: cleaning,
                deletedCount: deletedCount,
                skippedCount: skippedCount,
                reclaimedBytes: reclaimedBytes,
                cause: cleanupCause,
                error: cleanupError
            }
        }
    }

    Process {
        id: scanProcess
        property string output: ""
        stdout: StdioCollector { onStreamFinished: scanProcess.output = text }
        onExited: exitCode => {
            const parsed = root.parse(output)
            root.entries = parsed
            root.scannedAt = Date.now()
            root.error = exitCode === 0 || parsed.length > 0 ? ""
                : "Wallpaper cache inventory is unavailable"
            root.scanning = false
            root.buildPlan()
            if (root.automaticPending) {
                root.automaticPending = false
                root.cleanupCause = "automatic"
                Qt.callLater(root.executeAutomaticPlan)
            }
        }
    }

    function executeAutomaticPlan() {
        if (scanning || cleaning) {
            automaticPending = true
            return
        }
        const plan = buildPlan()
        if (plan.entries.length === 0)
            return
        cleanupError = ""
        deletedCount = 0
        skippedCount = 0
        reclaimedBytes = 0
        cleanupCause = "automatic"
        cleanupQueue = plan.entries.slice()
        cleaning = true
        cleanupState = "cleaning"
        startCleanupEntry()
    }

    Process {
        id: verifyProcess
        property string output: ""
        stdout: StdioCollector { onStreamFinished: verifyProcess.output = text }
        onExited: exitCode => {
            const entry = root.activeCleanupEntry
            const fields = String(output || "").split("|")
            const sizeMatches = Number(fields[0]) === Number(entry.size)
            const accessMatches = Math.abs(Number(fields[1]) * 1000
                - Number(entry.accessedAt)) < 1100
            if (exitCode !== 0 || !sizeMatches || !accessMatches
                    || !root.cachePathAllowed(entry.path)
                    || root.protectedPaths()[entry.path]) {
                root.skippedCount += 1
                root.activeCleanupEntry = ({})
                Qt.callLater(root.startCleanupEntry)
                return
            }
            deleteProcess.entry = entry
            deleteProcess.command = ["rm", "--", entry.path]
            deleteProcess.running = true
        }
    }

    Process {
        id: deleteProcess
        property var entry: ({})
        onExited: exitCode => {
            if (exitCode === 0) {
                root.deletedCount += 1
                root.reclaimedBytes += Number(entry.size) || 0
            } else {
                root.skippedCount += 1
                root.cleanupError = "Some cache files could not be removed"
            }
            root.activeCleanupEntry = ({})
            entry = ({})
            Qt.callLater(root.startCleanupEntry)
        }
    }

    Connections {
        target: WallpaperAssignmentService
        function onGlobalWallpaperChanged() { root.buildPlan() }
        function onScreenWallpapersChanged() { root.buildPlan() }
    }

    Connections {
        target: WallpaperRenderService
        function onScreensChanged() { root.buildPlan() }
    }

    Connections {
        target: WallpaperOptimizationService
        function onActiveOutputChanged() { root.buildPlan() }
        function onActiveTemporaryOutputChanged() { root.buildPlan() }
    }

    Connections {
        target: WallpaperPosterService
        function onRecordsChanged() { root.buildPlan() }
        function onActiveItemChanged() { root.buildPlan() }
        function onQueueChanged() { root.buildPlan() }
    }
}
