pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services.hardware
import qs.services.jobs
import qs.services.wallpaper
import "VideoCodecBenchmark.js" as Benchmark

Singleton {
    id: root

    readonly property string cacheDirectory:
        Quickshell.cachePath("codec-benchmarks")
    readonly property int candidateTimeoutMs: 2 * 60 * 1000
    readonly property int playbackRunMs: 5000
    readonly property int playbackRunsRequired: 3
    readonly property int playbackStartupTimeoutMs: 10000

    property string state: "idle"
    property string error: ""
    property string sourcePath: ""
    property var candidates: []
    property int candidateIndex: -1
    property var records: []
    property int generation: 0
    property bool directoryReady: false
    property bool directoryChecked: false
    property bool staleCleanupChecked: false
    property double startedAtMs: 0
    property int pendingElapsedMs: 0
    property string activeOutput: ""
    property int playbackRecordIndex: -1
    property int playbackRunIndex: 0

    readonly property bool busy: state === "preparing"
        || state === "encoding" || state === "verifying"
        || state === "playback-loading" || state === "playback-running"
    readonly property var activeCandidate: candidateIndex >= 0
            && candidateIndex < candidates.length
        ? candidates[candidateIndex] : null

    function snapshot() {
        return {
            state: state,
            error: error,
            sourcePath: sourcePath,
            boundedSample: {
                durationSeconds: 3,
                maximumWidth: 1280,
                maximumHeight: 720,
                frameRate: 24
            },
            candidateIndex: candidateIndex,
            candidateCount: candidates.length,
            activeCodec: activeCandidate ? activeCandidate.codec : "",
            records: records,
            playback: {
                activeRecordIndex: playbackRecordIndex,
                run: playbackRunIndex,
                requiredRuns: playbackRunsRequired,
                runDurationMs: playbackRunMs
            },
            persistence: "session-only",
            affectsSelection: false
        }
    }

    function request(path) {
        const source = String(path || "")
        if (busy || clearProcess.running || source.length === 0)
            return false
        const probe = WallpaperProbeService.recordFor(source)
        if (probe.state !== "ready" || probe.kind !== "video") {
            error = "Benchmark source must be an inspected video wallpaper"
            state = "failed"
            return false
        }
        if (VideoCapabilityService.state === "idle")
            VideoCapabilityService.refresh()
        generation += 1
        sourcePath = source
        error = ""
        state = "preparing"
        records = []
        candidates = []
        candidateIndex = -1
        directoryChecked = false
        directoryReady = false
        staleCleanupChecked = false
        directoryProcess.operationGeneration = generation
        directoryProcess.command = ["mkdir", "-p", "--", cacheDirectory]
        directoryProcess.running = true
        staleCleanupProcess.operationGeneration = generation
        staleCleanupProcess.command = ["find", cacheDirectory, "-maxdepth", "1",
            "-type", "f", "-name", "candidate-*.mp4", "-delete"]
        staleCleanupProcess.running = true
        tryPrepare()
        return true
    }

    function tryPrepare() {
        if (state !== "preparing" || !directoryChecked
                || !staleCleanupChecked
                || VideoCapabilityService.busy
                || !BackgroundJobTools.ready)
            return
        if (!directoryReady || VideoCapabilityService.ffmpegPath.length === 0) {
            fail(!directoryReady ? "Benchmark cache is unavailable"
                : "FFmpeg is unavailable")
            return
        }
        candidates = Benchmark.runnableCandidates(
            VideoCapabilityService.codecCandidates)
        if (candidates.length === 0) {
            fail("No verified codec candidate can be benchmarked")
            return
        }
        candidateIndex = 0
        encodeCurrent()
    }

    function outputFor(candidate) {
        return cacheDirectory + "/candidate-" + candidate.codec + "."
            + Benchmark.outputExtension(candidate.codec)
    }

    function encodeCurrent() {
        if (!activeCandidate) {
            state = "ready"
            activeOutput = ""
            return
        }
        activeOutput = outputFor(activeCandidate)
        const command = Benchmark.command(VideoCapabilityService.ffmpegPath,
            sourcePath, activeOutput, activeCandidate)
        if (command.length === 0) {
            appendRecord(false, 0, "Unsupported benchmark encoder")
            advance()
            return
        }
        state = "encoding"
        startedAtMs = Date.now()
        timeoutTimer.restart()
        encodeProcess.operationGeneration = generation
        encodeProcess.targetPath = activeOutput
        encodeProcess.command = BackgroundJobTools.wrap(command)
        encodeProcess.running = true
    }

    function appendRecord(succeeded, elapsedMs, recordError) {
        const candidate = activeCandidate || ({})
        const updated = records.slice()
        updated.push({
            codec: String(candidate.codec || ""),
            encoder: String(candidate.encoder || ""),
            encodeSucceeded: succeeded === true,
            encodeElapsedMs: Math.max(0, Math.round(Number(elapsedMs) || 0)),
            outputPath: succeeded ? activeOutput : "",
            artifactAvailable: succeeded === true,
            error: String(recordError || ""),
            qtPlaybackSucceeded: false,
            hardwareDecodeVerified: false,
            hardwareTexturesVerified: false,
            droppedFrameRatio: null,
            playbackRuns: 0,
            playbackMs: 0
        })
        records = updated
    }

    function advance() {
        timeoutTimer.stop()
        activeOutput = ""
        candidateIndex += 1
        if (candidateIndex >= candidates.length) {
            state = "ready"
            return
        }
        encodeCurrent()
    }

    function fail(message) {
        timeoutTimer.stop()
        state = "failed"
        error = String(message || "Codec benchmark failed")
        activeOutput = ""
    }

    function startPlayback() {
        if (state !== "ready" || busy)
            return false
        playbackRecordIndex = nextPlaybackRecord(0)
        playbackRunIndex = 0
        if (playbackRecordIndex < 0) {
            error = "No verified candidate artifact is available for playback"
            state = "failed"
            return false
        }
        beginPlaybackRun()
        return true
    }

    function nextPlaybackRecord(startIndex) {
        for (let index = Math.max(0, startIndex); index < records.length; ++index)
            if (records[index].encodeSucceeded
                    && String(records[index].outputPath || "").length > 0)
                return index
        return -1
    }

    function beginPlaybackRun() {
        playbackLoader.active = false
        playbackRestartTimer.restart()
    }

    function instantiatePlaybackRun() {
        if (playbackRecordIndex < 0
                || playbackRecordIndex >= records.length) {
            finishPlayback()
            return
        }
        state = "playback-loading"
        playbackLoader.active = true
        playbackStartupTimer.restart()
    }

    function tryStartPlaybackClock() {
        const item = playbackLoader.item
        if (state !== "playback-loading" || !item
                || !item.firstFrameReady || !item.actuallyPlaying)
            return
        playbackStartupTimer.stop()
        state = "playback-running"
        playbackRunTimer.restart()
    }

    function updatePlaybackRecord(values) {
        if (playbackRecordIndex < 0 || playbackRecordIndex >= records.length)
            return
        const updated = records.slice()
        updated[playbackRecordIndex] = Object.assign(
            {}, updated[playbackRecordIndex], values)
        records = updated
    }

    function completePlaybackRun() {
        const record = records[playbackRecordIndex]
        const runs = Number(record.playbackRuns || 0) + 1
        const elapsed = Number(record.playbackMs || 0) + playbackRunMs
        updatePlaybackRecord({
            playbackRuns: runs,
            playbackMs: elapsed,
            qtPlaybackSucceeded: true
        })
        playbackRunIndex = runs
        playbackLoader.active = false
        if (runs < playbackRunsRequired) {
            beginPlaybackRun()
            return
        }
        playbackRecordIndex = nextPlaybackRecord(playbackRecordIndex + 1)
        playbackRunIndex = 0
        if (playbackRecordIndex < 0) {
            finishPlayback()
            return
        }
        beginPlaybackRun()
    }

    function failPlaybackRun(message) {
        playbackStartupTimer.stop()
        playbackRunTimer.stop()
        updatePlaybackRecord({
            qtPlaybackSucceeded: false,
            error: String(message || "Qt Multimedia playback failed")
        })
        playbackLoader.active = false
        playbackRecordIndex = nextPlaybackRecord(playbackRecordIndex + 1)
        playbackRunIndex = 0
        if (playbackRecordIndex < 0)
            finishPlayback()
        else
            beginPlaybackRun()
    }

    function finishPlayback() {
        playbackStartupTimer.stop()
        playbackRunTimer.stop()
        playbackLoader.active = false
        playbackRecordIndex = -1
        playbackRunIndex = 0
        state = "playback-ready"
    }

    function cancel() {
        if (!busy)
            return false
        generation += 1
        timeoutTimer.stop()
        if (encodeProcess.running)
            encodeProcess.signal(15)
        playbackStartupTimer.stop()
        playbackRunTimer.stop()
        playbackRestartTimer.stop()
        playbackLoader.active = false
        discardOutput(activeOutput)
        cancelCleanupProcess.command = ["find", cacheDirectory, "-maxdepth", "1",
            "-type", "f", "-name", "candidate-*.mp4", "-delete"]
        cancelCleanupProcess.running = true
        records = records.map(record => Object.assign({}, record, {
            outputPath: "",
            artifactAvailable: false
        }))
        playbackRecordIndex = -1
        playbackRunIndex = 0
        state = "cancelled"
        error = "Benchmark cancelled"
        activeOutput = ""
        return true
    }

    function clear() {
        if (busy || clearProcess.running)
            return false
        records = []
        candidates = []
        sourcePath = ""
        candidateIndex = -1
        playbackRecordIndex = -1
        playbackRunIndex = 0
        state = "idle"
        error = ""
        clearProcess.command = ["find", cacheDirectory, "-maxdepth", "1",
            "-type", "f", "-name", "candidate-*.mp4", "-delete"]
        clearProcess.running = true
        return true
    }

    function discardOutput(path) {
        const output = String(path || "")
        if (!output.startsWith(cacheDirectory + "/candidate-")
                || !output.endsWith(".mp4"))
            return false
        cleanupProcess.command = ["rm", "-f", "--", output]
        cleanupProcess.running = true
        return true
    }

    Connections {
        target: VideoCapabilityService
        function onStateChanged() { root.tryPrepare() }
        function onCodecCandidatesChanged() { root.tryPrepare() }
    }

    Connections {
        target: BackgroundJobTools
        function onReadyChanged() { root.tryPrepare() }
    }

    Process {
        id: directoryProcess
        property int operationGeneration: 0
        onExited: exitCode => {
            if (operationGeneration !== root.generation)
                return
            root.directoryChecked = true
            root.directoryReady = exitCode === 0
            root.tryPrepare()
        }
    }

    Process {
        id: staleCleanupProcess
        property int operationGeneration: 0
        onExited: exitCode => {
            if (operationGeneration !== root.generation)
                return
            root.staleCleanupChecked = true
            root.tryPrepare()
        }
    }

    Process {
        id: encodeProcess
        property int operationGeneration: 0
        property string targetPath: ""
        stderr: StdioCollector { onStreamFinished: encodeProcess.output = text }
        property string output: ""
        onExited: exitCode => {
            if (operationGeneration !== root.generation) {
                root.discardOutput(targetPath)
                return
            }
            timeoutTimer.stop()
            const elapsed = Date.now() - root.startedAtMs
            if (exitCode !== 0) {
                root.appendRecord(false, elapsed,
                    output.trim() || "Encoder exited with " + exitCode)
                root.discardOutput(root.activeOutput)
                root.advance()
                return
            }
            root.state = "verifying"
            root.pendingElapsedMs = elapsed
            verifyProcess.operationGeneration = root.generation
            verifyProcess.output = ""
            verifyProcess.command = ["stat", "--printf=%s", "--",
                root.activeOutput]
            verifyProcess.running = true
        }
    }

    Process {
        id: verifyProcess
        property int operationGeneration: 0
        property string output: ""
        stdout: StdioCollector { onStreamFinished: verifyProcess.output = text }
        onExited: exitCode => {
            if (operationGeneration !== root.generation)
                return
            const bytes = Number(output.trim()) || 0
            const valid = exitCode === 0 && bytes > 0
            root.appendRecord(valid, root.pendingElapsedMs,
                valid ? "" : "Encoder produced no usable output")
            if (!valid)
                root.discardOutput(root.activeOutput)
            root.advance()
        }
    }

    Process { id: clearProcess }
    Process { id: cleanupProcess }
    Process { id: cancelCleanupProcess }

    Loader {
        id: playbackLoader
        active: false
        sourceComponent: Component {
            VideoCodecPlaybackProbe {
                path: root.playbackRecordIndex >= 0
                        && root.playbackRecordIndex < root.records.length
                    ? String(root.records[root.playbackRecordIndex].outputPath
                        || "") : ""
            }
        }
        onLoaded: root.tryStartPlaybackClock()
    }

    Connections {
        target: playbackLoader.item
        ignoreUnknownSignals: true
        function onActuallyPlayingChanged() { root.tryStartPlaybackClock() }
        function onFirstFrameReadyChanged() { root.tryStartPlaybackClock() }
        function onErrorChanged() {
            if (playbackLoader.item
                    && playbackLoader.item.error.length > 0)
                root.failPlaybackRun(playbackLoader.item.error)
        }
    }

    Timer {
        id: playbackRestartTimer
        interval: 0
        onTriggered: root.instantiatePlaybackRun()
    }

    Timer {
        id: playbackStartupTimer
        interval: root.playbackStartupTimeoutMs
        onTriggered: root.failPlaybackRun(
            "Qt Multimedia did not produce a playing frame within ten seconds")
    }

    Timer {
        id: playbackRunTimer
        interval: root.playbackRunMs
        onTriggered: root.completePlaybackRun()
    }

    Timer {
        id: timeoutTimer
        interval: root.candidateTimeoutMs
        onTriggered: {
            if (encodeProcess.running)
                encodeProcess.signal(15)
            root.generation += 1
            root.appendRecord(false, Date.now() - root.startedAtMs,
                "Encoder exceeded the two-minute candidate limit")
            root.discardOutput(root.activeOutput)
            root.fail("Codec benchmark stopped after a candidate timeout")
        }
    }
}
