pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services.config
import qs.services.wallpaper

Singleton {
    id: root

    readonly property var supportedExtensions: [
        "jpg", "jpeg", "png", "webp", "avif"
    ]
    readonly property var candidateExtensions: supportedExtensions.concat([
        "gif", "mp4", "webm", "mkv", "mov"
    ])
    readonly property var excludedDirectoryNames: [
        "screenshots", "captures", ".thumbnails"
    ]
    readonly property var directories: ConfigService.wallpaperDirectories
    readonly property bool configured: directories.length > 0
    property var wallpapers: []
    property var candidatePaths: []
    property bool scanning: false
    readonly property bool classifying: wallpapers.some(record =>
        record.state === "queued" || record.state === "probing")
    property string error: ""
    property var warnings: []

    property int requestedGeneration: 0
    property int activeGeneration: 0
    property bool scanPending: false

    function normalizedDirectories(input) {
        const unique = []
        const seen = ({})
        for (let value of input || []) {
            const path = String(value || "").trim().replace(/\/+$/, "")
            if (path.length === 0 || seen[path])
                continue
            seen[path] = true
            unique.push(path)
        }
        return unique
    }

    function isSupported(path) {
        const lower = String(path || "").toLowerCase()
        for (let extension of supportedExtensions) {
            if (lower.endsWith("." + extension))
                return true
        }
        return false
    }

    function isCandidate(path) {
        const lower = String(path || "").toLowerCase()
        for (let extension of candidateExtensions) {
            if (lower.endsWith("." + extension))
                return true
        }
        return false
    }

    function isExcluded(path) {
        const segments = String(path || "").toLowerCase().split("/")
        for (let segment of segments) {
            if (excludedDirectoryNames.indexOf(segment) >= 0)
                return true
        }
        return false
    }

    function parseOutput(output) {
        const unique = []
        const seen = ({})
        for (let line of String(output || "").split("\n")) {
            const path = line.trim()
            if (path.length === 0 || seen[path]
                    || !isCandidate(path) || isExcluded(path))
                continue
            seen[path] = true
            unique.push(path)
        }
        unique.sort((a, b) => a.localeCompare(b))
        return unique
    }

    function refreshRecords() {
        const refreshed = candidatePaths.map(path =>
            WallpaperProbeService.recordFor(path))
        if (refreshed.length === wallpapers.length
                && refreshed.every((record, index) =>
                    record === wallpapers[index]))
            return
        wallpapers = refreshed
    }

    function classify(paths) {
        WallpaperProbeService.cancelAll()
        candidatePaths = paths
        refreshRecords()
        for (const path of paths)
            WallpaperProbeService.enqueue(path)
    }

    function rescan(requestedDirectories) {
        if (requestedDirectories !== undefined)
            ConfigService.setWallpaperDirectories(
                normalizedDirectories(requestedDirectories))

        requestedGeneration += 1
        WallpaperProbeService.cancelAll()
        if (scanProcess.running) {
            scanPending = true
            return
        }
        startScan()
    }

    function startScan() {
        const roots = normalizedDirectories(directories)
        scanPending = false
        activeGeneration = requestedGeneration
        error = ""
        warnings = []

        if (roots.length === 0) {
            candidatePaths = []
            wallpapers = []
            scanning = false
            return
        }

        scanProcess.command = ["find"].concat(roots, [
            "-maxdepth", "3", "-type", "f", "-print"
        ])
        scanning = true
        scanProcess.running = true
    }

    Connections {
        target: WallpaperProbeService
        function onRecordsChanged() { root.refreshRecords() }
    }

    Process {
        id: scanProcess

        stdout: StdioCollector {
            onStreamFinished: {
                if (root.activeGeneration === root.requestedGeneration)
                    root.classify(root.parseOutput(text))
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (root.activeGeneration !== root.requestedGeneration)
                    return
                root.warnings = String(text || "").split("\n")
                    .map(line => line.trim())
                    .filter(line => line.length > 0)
            }
        }

        onExited: exitCode => {
            root.scanning = false
            if (root.activeGeneration === root.requestedGeneration
                    && exitCode !== 0 && root.wallpapers.length === 0)
                root.error = "Wallpaper discovery failed"
            if (root.scanPending
                    || root.activeGeneration !== root.requestedGeneration)
                root.startScan()
        }
    }
}
