import QtQuick
import Quickshell
import Quickshell.Io
import qs.services.hardware
import qs.services.jobs
import "VideoCodecBenchmark.js" as Benchmark

Item {
    id: root
    visible: false

    required property string cacheDirectory
    readonly property int candidateTimeoutMs: 2 * 60 * 1000

    property string state: "idle"
    property string error: ""
    property string sourcePath: ""
    property var candidates: []
    property int candidateIndex: -1
    property int generation: 0
    property bool directoryReady: false
    property bool directoryChecked: false
    property bool staleCleanupChecked: false
    property double startedAtMs: 0
    property int pendingElapsedMs: 0
    property string activeOutput: ""

    readonly property bool busy: state === "preparing"
        || state === "encoding" || state === "verifying"
    readonly property bool clearing: clearProcess.running
    readonly property var activeCandidate: candidateIndex >= 0
            && candidateIndex < candidates.length
        ? candidates[candidateIndex] : null
    readonly property string activeCodec:
        activeCandidate ? String(activeCandidate.codec || "") : ""

    signal recordProduced(var record)
    signal completed()
    signal failed(string message)

    function request(path) {
        const source = String(path || "")
        if (busy || clearProcess.running || source.length === 0)
            return false
        generation += 1
        sourcePath = source
        error = ""
        state = "preparing"
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
                || !staleCleanupChecked || VideoCapabilityService.busy
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
            completed()
            return
        }
        activeOutput = outputFor(activeCandidate)
        const command = Benchmark.command(VideoCapabilityService.ffmpegPath,
            sourcePath, activeOutput, activeCandidate)
        if (command.length === 0) {
            publishRecord(false, 0, "Unsupported benchmark encoder")
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

    function publishRecord(succeeded, elapsedMs, recordError) {
        const candidate = activeCandidate || ({})
        recordProduced({
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
            playbackMs: 0,
            frameHandleTypes: [],
            frameHandleObservation: "unavailable",
            frameHandleError: "",
            hardwareDecodeBackend: "",
            hardwareDecodeError: "",
            playbackMeasurements: [],
            observedFrames: 0,
            expectedFrames: 0,
            droppedFrames: 0
        })
    }

    function advance() {
        timeoutTimer.stop()
        activeOutput = ""
        candidateIndex += 1
        if (candidateIndex >= candidates.length) {
            state = "ready"
            completed()
            return
        }
        encodeCurrent()
    }

    function fail(message) {
        timeoutTimer.stop()
        state = "failed"
        error = String(message || "Codec benchmark failed")
        activeOutput = ""
        failed(error)
    }

    function cancel() {
        if (!busy)
            return false
        generation += 1
        timeoutTimer.stop()
        if (encodeProcess.running)
            encodeProcess.signal(15)
        discardOutput(activeOutput)
        cleanupCandidates()
        state = "cancelled"
        error = "Benchmark cancelled"
        activeOutput = ""
        return true
    }

    function clearArtifacts() {
        if (busy || clearProcess.running)
            return false
        clearProcess.command = ["find", cacheDirectory, "-maxdepth", "1",
            "-type", "f", "-name", "candidate-*.mp4", "-delete"]
        clearProcess.running = true
        state = "idle"
        error = ""
        candidates = []
        candidateIndex = -1
        return true
    }

    function cleanupCandidates() {
        cancelCleanupProcess.command = ["find", cacheDirectory, "-maxdepth", "1",
            "-type", "f", "-name", "candidate-*.mp4", "-delete"]
        cancelCleanupProcess.running = true
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
        property string output: ""
        stderr: StdioCollector { onStreamFinished: encodeProcess.output = text }
        onExited: exitCode => {
            if (operationGeneration !== root.generation) {
                root.discardOutput(targetPath)
                return
            }
            timeoutTimer.stop()
            const elapsed = Date.now() - root.startedAtMs
            if (exitCode !== 0) {
                root.publishRecord(false, elapsed,
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
            root.publishRecord(valid, root.pendingElapsedMs,
                valid ? "" : "Encoder produced no usable output")
            if (!valid)
                root.discardOutput(root.activeOutput)
            root.advance()
        }
    }

    Process { id: clearProcess }
    Process { id: cleanupProcess }
    Process { id: cancelCleanupProcess }

    Timer {
        id: timeoutTimer
        interval: root.candidateTimeoutMs
        onTriggered: {
            if (encodeProcess.running)
                encodeProcess.signal(15)
            root.generation += 1
            root.publishRecord(false, Date.now() - root.startedAtMs,
                "Encoder exceeded the two-minute candidate limit")
            root.discardOutput(root.activeOutput)
            root.fail("Codec benchmark stopped after a candidate timeout")
        }
    }
}
