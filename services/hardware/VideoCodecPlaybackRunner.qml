import QtQuick
import "VideoPlaybackMetrics.js" as PlaybackMetrics

Item {
    id: root
    visible: false

    required property int runDurationMs
    required property int startupTimeoutMs

    property string state: "idle"
    property double measurementStartedAtMs: 0

    readonly property bool busy: state === "loading" || state === "running"

    signal completed(var evidence)
    signal failed(string message)

    function start(path) {
        if (busy || String(path || "").length === 0)
            return false
        state = "loading"
        playbackLoader.setSource(
            Qt.resolvedUrl("VideoCodecPlaybackProbe.qml"), {
                path: String(path)
            })
        playbackLoader.active = true
        startupTimer.restart()
        tryStartClock()
        return true
    }

    function tryStartClock() {
        const item = playbackLoader.item
        if (state !== "loading" || !item
                || !item.firstFrameReady || !item.actuallyPlaying)
            return
        startupTimer.stop()
        state = "running"
        item.beginFrameMeasurement()
        measurementStartedAtMs = Date.now()
        runTimer.restart()
    }

    function finishRun() {
        const item = playbackLoader.item
        const observedFrames = item ? item.endFrameMeasurement() : 0
        const measurement = PlaybackMetrics.run(24, runDurationMs,
            observedFrames, Date.now() - measurementStartedAtMs)
        if (!measurement.valid) {
            failRun(measurement.error)
            return
        }
        const evidence = {
            measurement: measurement,
            frameHandleType: item
                ? String(item.frameHandleType || "unavailable") : "unavailable",
            frameHandleError: item ? String(item.frameHandleError || "") : ""
        }
        reset("ready")
        completed(evidence)
    }

    function failRun(message) {
        const failure = String(message || "Qt Multimedia playback failed")
        reset("failed")
        failed(failure)
    }

    function cancel() {
        if (!busy)
            return false
        reset("cancelled")
        return true
    }

    function reset(nextState) {
        startupTimer.stop()
        runTimer.stop()
        playbackLoader.active = false
        state = nextState
        measurementStartedAtMs = 0
    }

    Loader {
        id: playbackLoader
        active: false
        onLoaded: root.tryStartClock()
    }

    Connections {
        target: playbackLoader.item
        ignoreUnknownSignals: true
        function onActuallyPlayingChanged() { root.tryStartClock() }
        function onFirstFrameReadyChanged() { root.tryStartClock() }
        function onErrorChanged() {
            if (playbackLoader.item
                    && playbackLoader.item.error.length > 0)
                root.failRun(playbackLoader.item.error)
        }
    }

    Timer {
        id: startupTimer
        interval: root.startupTimeoutMs
        onTriggered: root.failRun(
            "Qt Multimedia did not produce a playing frame within ten seconds")
    }

    Timer {
        id: runTimer
        interval: root.runDurationMs
        onTriggered: root.finishRun()
    }
}
