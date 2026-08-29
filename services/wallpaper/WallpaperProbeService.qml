pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property int maximumQueueSize: 64
    readonly property int maximumCacheEntries: 512
    readonly property int probeTimeout: 5000
    property var records: ({})
    property var queue: []
    property string activePath: ""
    property string activeIdentity: ""
    property int generation: 0
    property bool cacheLoaded: false
    property var cacheEntries: ({})

    readonly property bool busy: activePath.length > 0 || queue.length > 0

    function emptyRecord(path, state, error) {
        return {
            path: String(path || ""),
            state: state,
            kind: "unsupported",
            width: 0,
            height: 0,
            durationMs: 0,
            frameRate: 0,
            bitRate: 0,
            codec: "",
            container: "",
            cached: false,
            error: String(error || "")
        }
    }

    function recordFor(path) {
        return records[String(path || "")]
            || emptyRecord(path, "unknown", "")
    }

    function identityFor(path) {
        const entry = cacheEntries[String(path || "")]
        return entry ? String(entry.identity || "") : ""
    }

    function publish(path, record) {
        const previous = records[path]
        if (previous && JSON.stringify(previous) === JSON.stringify(record))
            return
        const updated = ({})
        for (const key in records)
            updated[key] = records[key]
        updated[path] = record
        records = updated
    }

    function durationMilliseconds(stream, format) {
        const streamDuration = Number(stream.duration)
        const formatDuration = Number(format.duration)
        const seconds = Number.isFinite(streamDuration) && streamDuration > 0
            ? streamDuration
            : Number.isFinite(formatDuration) && formatDuration > 0
                ? formatDuration : 0
        return Math.round(seconds * 1000)
    }

    function rationalNumber(value) {
        const text = String(value || "")
        const parts = text.split("/")
        const numerator = Number(parts[0])
        const denominator = parts.length > 1 ? Number(parts[1]) : 1
        return Number.isFinite(numerator) && Number.isFinite(denominator)
                && denominator !== 0 ? numerator / denominator : 0
    }

    function classify(path, payload) {
        const streams = payload.streams || []
        if (streams.length === 0)
            return emptyRecord(path, "unsupported", "No video or image stream")

        const stream = streams[0] || ({})
        const format = payload.format || ({})
        const codec = String(stream.codec_name || "").toLowerCase()
        const container = String(format.format_name || "").toLowerCase()
        const majorBrand = String((format.tags || ({})).major_brand || "")
            .toLowerCase()
        const width = Math.max(0, Number(stream.width) || 0)
        const height = Math.max(0, Number(stream.height) || 0)
        const durationMs = durationMilliseconds(stream, format)
        const frameRate = rationalNumber(stream.avg_frame_rate
            || stream.r_frame_rate)
        const bitRate = Math.max(0, Number(stream.bit_rate)
            || Number(format.bit_rate) || 0)
        const frames = Number(stream.nb_frames)
        let kind = "unsupported"

        if (codec === "webp_anim"
                || (codec === "gif" && Number.isFinite(frames) && frames > 1)) {
            kind = "animatedImage"
        } else if ((["png", "mjpeg", "webp"].indexOf(codec) >= 0
                    && (container.indexOf("_pipe") >= 0
                        || container === "image2"))
                || (codec === "av1" && majorBrand.indexOf("avi") >= 0
                    && (!Number.isFinite(frames) || frames <= 1))) {
            kind = "static"
        } else if (["h264", "hevc", "vp8", "vp9", "av1"].indexOf(codec) >= 0
                && (container.indexOf("mp4") >= 0
                    || container.indexOf("mov") >= 0
                    || container.indexOf("matroska") >= 0
                    || container.indexOf("webm") >= 0)) {
            kind = "video"
        }

        if (kind === "unsupported")
            return emptyRecord(path, "unsupported",
                "Unsupported codec/container combination")
        if (width <= 0 || height <= 0)
            return emptyRecord(path, "failed", "Media dimensions are unavailable")

        return {
            path: path,
            state: "ready",
            kind: kind,
            width: width,
            height: height,
            durationMs: durationMs,
            frameRate: frameRate,
            bitRate: bitRate,
            codec: codec,
            container: container,
            cached: false,
            error: ""
        }
    }

    function cachedRecord(path, identity) {
        const entry = cacheEntries[path]
        if (!entry || String(entry.identity || "") !== identity)
            return null
        const record = entry.record || ({})
        if (record.state !== "ready")
            return null
        if (record.kind === "video"
                && (record.frameRate === undefined
                    || record.bitRate === undefined))
            return null
        return Object.assign({}, record, { cached: true })
    }

    function storeCache(path, identity, record) {
        if (record.state !== "ready")
            return
        const entries = []
        for (const key in cacheEntries) {
            if (key !== path) {
                const existing = cacheEntries[key]
                entries.push({ path: key, entry: existing,
                    touchedAt: Number(existing.touchedAt) || 0 })
            }
        }
        entries.sort((a, b) => b.touchedAt - a.touchedAt)

        const updated = ({})
        updated[path] = {
            identity: identity,
            touchedAt: Date.now(),
            record: Object.assign({}, record, { cached: false })
        }
        for (let index = 0;
                index < entries.length && index < maximumCacheEntries - 1;
                ++index)
            updated[entries[index].path] = entries[index].entry
        cacheEntries = updated
        cacheSaveTimer.restart()
    }

    function enqueue(path) {
        const normalized = String(path || "").trim()
        if (normalized.length === 0)
            return false
        if (activePath === normalized || queue.indexOf(normalized) >= 0)
            return true
        if (queue.length >= maximumQueueSize) {
            publish(normalized, emptyRecord(normalized, "failed",
                "Wallpaper probe queue is full"))
            return false
        }
        if (recordFor(normalized).state !== "ready")
            publish(normalized, emptyRecord(normalized, "queued", ""))
        queue = queue.concat([normalized])
        startNext()
        return true
    }

    function cancelAll() {
        const canceled = queue.slice()
        if (activePath.length > 0)
            canceled.push(activePath)
        for (const path of canceled)
            publish(path, emptyRecord(path, "cancelled", "Probe cancelled"))
        generation += 1
        queue = []
        timeoutTimer.stop()
        if (probeProcess.running)
            probeProcess.running = false
        if (statProcess.running)
            statProcess.running = false
        activePath = ""
        activeIdentity = ""
    }

    function startNext() {
        if (!WallpaperMediaTools.probeChecked
                || statProcess.running || probeProcess.running
                || activePath.length > 0 || queue.length === 0)
            return
        const remaining = queue.slice()
        const path = remaining.shift()
        queue = remaining
        activePath = path
        activeIdentity = ""
        if (WallpaperMediaTools.ffprobePath.length === 0) {
            publish(path, emptyRecord(path, "failed",
                "FFprobe is unavailable"))
            activePath = ""
            Qt.callLater(startNext)
            return
        }
        if (recordFor(path).state !== "ready")
            publish(path, emptyRecord(path, "probing", ""))
        statProcess.statGeneration = generation
        statProcess.statPath = path
        statProcess.output = ""
        statProcess.command = ["stat", "--printf=%s|%y", "--", path]
        timeoutTimer.restart()
        statProcess.running = true
    }

    function startProbe(path) {
        probeProcess.probeGeneration = generation
        probeProcess.probePath = path
        probeProcess.output = ""
        probeProcess.command = [
            WallpaperMediaTools.ffprobePath,
            "-v", "error", "-select_streams", "v:0",
            "-show_entries",
            "stream=codec_name,width,height,nb_frames,duration,avg_frame_rate,r_frame_rate,bit_rate:format=format_name,duration,bit_rate:format_tags=major_brand",
            "-of", "json", "--", path
        ]
        probeProcess.running = true
    }

    Connections {
        target: WallpaperMediaTools
        function onProbeCheckedChanged() { root.startNext() }
    }

    function finishActive() {
        timeoutTimer.stop()
        activePath = ""
        activeIdentity = ""
        Qt.callLater(startNext)
    }

    Timer {
        id: timeoutTimer
        interval: root.probeTimeout
        onTriggered: {
            const path = root.activePath
            if (path.length === 0)
                return
            root.publish(path, root.emptyRecord(path, "failed",
                "Wallpaper probe timed out"))
            if (probeProcess.running)
                probeProcess.running = false
            if (statProcess.running)
                statProcess.running = false
            root.finishActive()
        }
    }

    Process {
        id: statProcess
        property string statPath: ""
        property int statGeneration: 0
        property string output: ""

        stdout: StdioCollector {
            onStreamFinished: statProcess.output = text
        }

        onExited: exitCode => {
            const path = statPath
            if (statGeneration !== root.generation || path !== root.activePath)
                return
            const identity = String(output || "")
            if (exitCode !== 0 || identity.length === 0) {
                root.publish(path, root.emptyRecord(path, "failed",
                    "Wallpaper source is unavailable"))
                root.finishActive()
                return
            }
            root.activeIdentity = identity
            const cached = root.cachedRecord(path, identity)
            if (cached) {
                root.publish(path, cached)
                root.finishActive()
                return
            }
            root.startProbe(path)
        }
    }

    Process {
        id: probeProcess
        property string probePath: ""
        property int probeGeneration: 0
        property string output: ""

        stdout: StdioCollector {
            onStreamFinished: probeProcess.output = text
        }

        onExited: exitCode => {
            const path = probePath
            if (probeGeneration !== root.generation || path !== root.activePath)
                return

            if (exitCode !== 0) {
                root.publish(path, root.emptyRecord(path, "failed",
                    "Media metadata probe failed"))
            } else {
                try {
                    const record = root.classify(path,
                        JSON.parse(probeProcess.output || "{}"))
                    root.storeCache(path, root.activeIdentity, record)
                    root.publish(path, record)
                } catch (error) {
                    root.publish(path, root.emptyRecord(path, "failed",
                        "Media metadata is invalid"))
                }
            }
            root.finishActive()
        }
    }

    Timer {
        id: cacheSaveTimer
        interval: 180
        onTriggered: cacheFile.writeAdapter()
    }

    FileView {
        id: cacheFile
        path: Quickshell.cachePath("wallpaper-probes.json")
        watchChanges: false
        printErrors: false
        onLoaded: {
            root.cacheEntries = cacheData.entries || ({})
            root.cacheLoaded = true
        }
        onLoadFailed: {
            root.cacheEntries = ({})
            root.cacheLoaded = true
        }

        JsonAdapter {
            id: cacheData
            property var entries: root.cacheEntries
        }
    }
}
