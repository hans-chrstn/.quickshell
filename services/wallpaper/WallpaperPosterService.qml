pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services.wallpaper

Singleton {
    id: root

    readonly property int posterWidth: 480
    readonly property int posterHeight: 270
    readonly property int maximumQueueSize: 32
    readonly property int generationTimeout: 10000
    readonly property string cacheDirectory:
        Quickshell.cachePath("wallpaper-posters")

    property var records: ({})
    property var queue: []
    property string activePath: ""
    property var activeItem: ({})
    property int generation: 0
    property bool directoryReady: false

    function emptyRecord(path, state, error) {
        return {
            path: String(path || ""),
            state: state,
            posterPath: "",
            pendingPosterPath: "",
            cached: false,
            stale: false,
            error: String(error || "")
        }
    }

    function recordFor(path) {
        return records[String(path || "")]
            || emptyRecord(path, "unknown", "")
    }

    function publish(path, record) {
        const updated = ({})
        for (const key in records)
            updated[key] = records[key]
        updated[path] = record
        records = updated
    }

    function workingRecord(item, state) {
        return Object.assign(emptyRecord(item.path, state, ""), {
            identity: item.identity,
            posterPath: item.fallbackPosterPath || item.posterPath,
            pendingPosterPath: item.posterPath,
            stale: Boolean(item.fallbackPosterPath)
        })
    }

    function failedRecord(item, error) {
        return Object.assign(emptyRecord(item.path, "failed", error), {
            identity: item.identity,
            posterPath: item.fallbackPosterPath || "",
            pendingPosterPath: item.posterPath,
            stale: Boolean(item.fallbackPosterPath)
        })
    }

    function posterPath(path, identity) {
        const key = Qt.md5(path + "|" + identity + "|"
            + posterWidth + "x" + posterHeight)
        return cacheDirectory + "/" + key + ".png"
    }

    function request(mediaRecord) {
        const path = String(mediaRecord?.path || "")
        const kind = String(mediaRecord?.kind || "")
        if (path.length === 0 || mediaRecord?.state !== "ready"
                || (kind !== "animatedImage" && kind !== "video"))
            return false
        const identity = WallpaperProbeService.identityFor(path)
        if (identity.length === 0)
            return false
        if (activePath === path || queue.some(item => item.path === path))
            return true
        const existing = records[path]
        const output = posterPath(path, identity)
        if (existing && existing.identity === identity
                && existing.posterPath === output
                && (existing.state === "ready" || existing.state === "checking"))
            return true
        if (queue.length >= maximumQueueSize) {
            publish(path, failedRecord({
                path: path,
                identity: identity,
                posterPath: output,
                fallbackPosterPath: existing?.posterPath || ""
            }, "Poster queue is full"))
            return false
        }
        const item = {
            path: path,
            identity: identity,
            posterPath: output,
            fallbackPosterPath: existing?.posterPath
                && existing.posterPath !== output ? existing.posterPath : "",
            durationMs: Number(mediaRecord.durationMs) || 0
        }
        publish(path, workingRecord(item, "queued"))
        queue = queue.concat([item])
        startNext()
        return true
    }

    function cancelAll() {
        const canceled = queue.slice()
        if (activePath.length > 0)
            canceled.push(activeItem)
        for (const item of canceled) {
            publish(item.path, Object.assign(
                failedRecord(item, "Poster cancelled"), { state: "cancelled" }))
        }
        generation += 1
        queue = []
        timeoutTimer.stop()
        if (checkProcess.running) checkProcess.running = false
        if (posterProcess.running) posterProcess.running = false
        activePath = ""
        activeItem = ({})
    }

    function startNext() {
        if (!directoryReady || !WallpaperMediaTools.posterChecked
                || activePath.length > 0
                || checkProcess.running || posterProcess.running
                || queue.length === 0)
            return
        const remaining = queue.slice()
        const item = remaining.shift()
        queue = remaining
        activePath = item.path
        activeItem = item
        checkProcess.item = item
        checkProcess.itemGeneration = generation
        checkProcess.output = ""
        publish(item.path, workingRecord(item, "checking"))
        checkProcess.command = ["stat", "--printf=%s", "--", item.posterPath]
        timeoutTimer.restart()
        checkProcess.running = true
    }

    function generate(item) {
        if (WallpaperMediaTools.ffmpegPath.length === 0) {
            publish(item.path, failedRecord(item, "FFmpeg is unavailable"))
            finishActive()
            return
        }
        const seekSeconds = Math.min(5,
            Math.max(0, item.durationMs / 1000 * 0.1))
        posterProcess.item = item
        posterProcess.itemGeneration = generation
        posterProcess.command = [
            WallpaperMediaTools.ffmpegPath, "-v", "error", "-y",
            "-threads", "1", "-filter_threads", "1",
            "-ss", seekSeconds.toFixed(3), "-i", item.path,
            "-frames:v", "1", "-vf",
            "scale=" + posterWidth + ":" + posterHeight
                + ":force_original_aspect_ratio=increase,crop="
                + posterWidth + ":" + posterHeight,
            item.posterPath
        ]
        publish(item.path, workingRecord(item, "generating"))
        posterProcess.running = true
    }

    function finishActive() {
        timeoutTimer.stop()
        activePath = ""
        activeItem = ({})
        Qt.callLater(startNext)
    }

    Component.onCompleted: {
        directoryProcess.command = ["mkdir", "-p", "--", cacheDirectory]
        directoryProcess.running = true
    }

    Connections {
        target: WallpaperMediaTools
        function onPosterCheckedChanged() { root.startNext() }
    }

    Timer {
        id: timeoutTimer
        interval: root.generationTimeout
        onTriggered: {
            const path = root.activePath
            if (path.length === 0) return
            root.publish(path, root.failedRecord(root.activeItem,
                "Poster generation timed out"))
            if (checkProcess.running) checkProcess.running = false
            if (posterProcess.running) posterProcess.running = false
            root.finishActive()
        }
    }

    Process {
        id: directoryProcess
        onExited: exitCode => {
            root.directoryReady = exitCode === 0
            if (root.directoryReady) root.startNext()
        }
    }

    Process {
        id: checkProcess
        property var item: ({})
        property int itemGeneration: 0
        property string output: ""
        stdout: StdioCollector { onStreamFinished: checkProcess.output = text }
        onExited: exitCode => {
            if (itemGeneration !== root.generation
                    || item.path !== root.activePath) return
            if (exitCode === 0 && Number(output) > 0) {
                root.publish(item.path, {
                    path: item.path,
                    state: "ready",
                    identity: item.identity,
                    posterPath: item.posterPath,
                    pendingPosterPath: "",
                    cached: true,
                    stale: false,
                    error: ""
                })
                root.finishActive()
            } else {
                root.generate(item)
            }
        }
    }

    Process {
        id: posterProcess
        property var item: ({})
        property int itemGeneration: 0
        onExited: exitCode => {
            if (itemGeneration !== root.generation
                    || item.path !== root.activePath) return
            if (exitCode === 0) {
                root.publish(item.path, {
                    path: item.path,
                    state: "ready",
                    identity: item.identity,
                    posterPath: item.posterPath,
                    pendingPosterPath: "",
                    cached: false,
                    stale: false,
                    error: ""
                })
            } else {
                root.publish(item.path, root.failedRecord(item,
                    "Poster generation failed"))
            }
            root.finishActive()
        }
    }
}
