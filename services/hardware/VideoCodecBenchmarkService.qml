pragma Singleton

import QtQuick
import Quickshell
import "../../core/JsonCopy.js" as JsonCopy
import qs.services.hardware
import qs.services.wallpaper
import "VideoHardwareEvidence.js" as HardwareEvidence
import "VideoPlaybackMetrics.js" as PlaybackMetrics

Singleton {
    id: root

    readonly property string cacheDirectory:
        Quickshell.cachePath("codec-benchmarks")
    readonly property int playbackRunMs: 5000
    readonly property int playbackRunsRequired: 3
    readonly property int playbackStartupTimeoutMs: 10000
    readonly property int hardwareProbeMs: 4000

    property string state: "idle"
    property string error: ""
    property string sourcePath: ""
    property var records: []
    property int playbackRecordIndex: -1
    property int playbackRunIndex: 0
    property int hardwareRecordIndex: -1

    readonly property bool busy: state === "preparing"
        || state === "encoding" || state === "verifying"
        || state === "playback-loading" || state === "playback-running"
        || state === "hardware-probing"

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
            candidateIndex: encoder.candidateIndex,
            candidateCount: encoder.candidates.length,
            activeCodec: encoder.activeCodec,
            records: JsonCopy.value(records),
            playback: {
                activeRecordIndex: playbackRecordIndex,
                run: playbackRunIndex,
                requiredRuns: playbackRunsRequired,
                runDurationMs: playbackRunMs
            },
            hardwareProbe: {
                activeRecordIndex: hardwareRecordIndex,
                durationMs: hardwareProbeMs,
                backendEvidence: "qt-ffmpeg-log",
                textureEvidence: "unavailable-in-qml"
            },
            persistence: "session-only",
            affectsSelection: VideoCapabilityService.codecEvaluations.some(
                candidate => candidate.measurementAccepted === true)
        }
    }

    function request(path) {
        const source = String(path || "")
        if (busy || encoder.clearing || source.length === 0)
            return false
        const probe = WallpaperProbeService.recordFor(source)
        if (probe.state !== "ready" || probe.kind !== "video") {
            error = "Benchmark source must be an inspected video wallpaper"
            state = "failed"
            return false
        }
        if (VideoCapabilityService.state === "idle")
            VideoCapabilityService.refresh()
        sourcePath = source
        error = ""
        records = []
        if (!encoder.request(source))
            return false
        state = "preparing"
        return true
    }

    function appendRecord(record) {
        const updated = records.slice()
        updated.push(record)
        records = updated
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
        playbackRestartTimer.restart()
    }

    function instantiatePlaybackRun() {
        if (playbackRecordIndex < 0
                || playbackRecordIndex >= records.length) {
            finishPlayback()
            return
        }
        if (!playbackRunner.start(
                String(records[playbackRecordIndex].outputPath || "")))
            failPlaybackRun("Qt Multimedia playback runner is unavailable")
    }

    function updatePlaybackRecord(values) {
        if (playbackRecordIndex < 0 || playbackRecordIndex >= records.length)
            return
        const updated = records.slice()
        updated[playbackRecordIndex] = Object.assign(
            {}, updated[playbackRecordIndex], values)
        records = updated
    }

    function completePlaybackRun(evidence) {
        const record = records[playbackRecordIndex]
        const runs = Number(record.playbackRuns || 0) + 1
        const elapsed = Number(record.playbackMs || 0) + playbackRunMs
        const measurement = evidence.measurement
        const handleType = String(evidence.frameHandleType || "unavailable")
        const handleError = String(evidence.frameHandleError || "")
        const handles = Array.from(record.frameHandleTypes || [])
        handles.push(handleType)
        const allRhiTextures = handles.length === playbackRunsRequired
            && handles.every(value => value === "rhi-texture")
        const measurements = Array.from(record.playbackMeasurements || [])
        measurements.push(measurement)
        const aggregate = PlaybackMetrics.aggregate(measurements)
        updatePlaybackRecord({
            playbackRuns: runs,
            playbackMs: elapsed,
            qtPlaybackSucceeded: true,
            frameHandleTypes: handles,
            frameHandleObservation: handleType,
            frameHandleError: handleError,
            hardwareTexturesVerified: allRhiTextures,
            playbackMeasurements: measurements,
            observedFrames: aggregate.observedFrames,
            expectedFrames: aggregate.expectedFrames,
            droppedFrames: aggregate.droppedFrames,
            droppedFrameRatio: aggregate.validRuns === playbackRunsRequired
                ? aggregate.droppedFrameRatio : null
        })
        playbackRunIndex = runs
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
        updatePlaybackRecord({
            qtPlaybackSucceeded: false,
            error: String(message || "Qt Multimedia playback failed")
        })
        playbackRecordIndex = nextPlaybackRecord(playbackRecordIndex + 1)
        playbackRunIndex = 0
        if (playbackRecordIndex < 0)
            finishPlayback()
        else
            beginPlaybackRun()
    }

    function finishPlayback() {
        playbackRunner.cancel()
        playbackRecordIndex = -1
        playbackRunIndex = 0
        state = "playback-ready"
    }

    function startHardwareProbe() {
        if (state !== "playback-ready" || busy)
            return false
        hardwareRecordIndex = nextHardwareRecord(0)
        if (hardwareRecordIndex < 0) {
            error = "No playback-compatible candidate is available"
            state = "failed"
            return false
        }
        runHardwareProbe()
        return true
    }

    function nextHardwareRecord(startIndex) {
        for (let index = Math.max(0, startIndex); index < records.length; ++index) {
            const record = records[index]
            if (record.qtPlaybackSucceeded && record.artifactAvailable
                    && String(record.outputPath || "").length > 0)
                return index
        }
        return -1
    }

    function runHardwareProbe() {
        if (hardwareRecordIndex < 0
                || hardwareRecordIndex >= records.length) {
            finishHardwareProbe()
            return
        }
        hardwareRestartTimer.restart()
    }

    function instantiateHardwareProbe() {
        if (hardwareRecordIndex < 0
                || hardwareRecordIndex >= records.length) {
            finishHardwareProbe()
            return
        }
        state = "hardware-probing"
        if (!hardwareRunner.start(records[hardwareRecordIndex].outputPath)) {
            error = "Hardware playback probe is unavailable"
            state = "failed"
        }
    }

    function applyHardwareResult(recordIndex, output) {
        if (recordIndex < 0 || recordIndex >= records.length)
            return
        const record = records[recordIndex]
        const result = HardwareEvidence.parseQtFfmpegLog(output, record.codec)
        const updated = records.slice()
        updated[recordIndex] = Object.assign({}, record, {
            hardwareDecodeVerified: result.hardwareDecodeVerified,
            hardwareDecodeBackend: result.backend,
            hardwareDecodeError: result.error
        })
        records = updated
    }

    function finishHardwareProbe() {
        hardwareRunner.cancel()
        hardwareRecordIndex = -1
        VideoCapabilityService.acceptBenchmarkRecords(records)
        state = "hardware-ready"
    }

    function cancel() {
        if (!busy)
            return false
        encoder.cancel()
        // Later evidence phases no longer keep the encoder busy, but cancelling
        // the overall benchmark still owns removal of its session artifacts.
        encoder.cleanupCandidates()
        playbackRestartTimer.stop()
        hardwareRestartTimer.stop()
        playbackRunner.cancel()
        hardwareRunner.cancel()
        records = records.map(record => Object.assign({}, record, {
            outputPath: "",
            artifactAvailable: false
        }))
        playbackRecordIndex = -1
        playbackRunIndex = 0
        hardwareRecordIndex = -1
        state = "cancelled"
        error = "Benchmark cancelled"
        return true
    }

    function clear() {
        if (busy || !encoder.clearArtifacts())
            return false
        records = []
        sourcePath = ""
        playbackRecordIndex = -1
        playbackRunIndex = 0
        state = "idle"
        error = ""
        VideoCapabilityService.clearBenchmarkEvidence()
        return true
    }

    VideoCodecBenchmarkEncoder {
        id: encoder
        cacheDirectory: root.cacheDirectory

        onStateChanged: {
            if (state === "preparing" || state === "encoding"
                    || state === "verifying")
                root.state = state
        }
        onRecordProduced: record => root.appendRecord(record)
        onCompleted: root.state = "ready"
        onFailed: message => {
            root.error = message
            root.state = "failed"
        }
    }

    VideoCodecPlaybackRunner {
        id: playbackRunner
        runDurationMs: root.playbackRunMs
        startupTimeoutMs: root.playbackStartupTimeoutMs
        onStateChanged: {
            if (state === "loading") root.state = "playback-loading"
            else if (state === "running") root.state = "playback-running"
        }
        onCompleted: evidence => root.completePlaybackRun(evidence)
        onFailed: message => root.failPlaybackRun(message)
    }

    VideoCodecHardwareProbeRunner {
        id: hardwareRunner
        durationMs: root.hardwareProbeMs
        onCompleted: output => {
            const completedIndex = root.hardwareRecordIndex
            root.applyHardwareResult(completedIndex, output)
            root.hardwareRecordIndex = root.nextHardwareRecord(
                completedIndex + 1)
            if (root.hardwareRecordIndex < 0)
                root.finishHardwareProbe()
            else
                root.runHardwareProbe()
        }
    }

    Timer {
        id: playbackRestartTimer
        interval: 0
        onTriggered: root.instantiatePlaybackRun()
    }

    Timer {
        id: hardwareRestartTimer
        interval: 0
        onTriggered: root.instantiateHardwareProbe()
    }

}
