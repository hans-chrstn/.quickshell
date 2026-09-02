import QtQuick
import QtMultimedia
import qs.core

Item {
    id: root

    required property string path

    readonly property bool actuallyPlaying:
        player.playbackState === MediaPlayer.PlayingState
    readonly property string error: player.error !== MediaPlayer.NoError
        ? String(player.errorString || "Qt Multimedia playback failed") : ""
    property bool firstFrameReady: false
    property bool measuringFrames: false
    property int observedFrames: 0
    property string frameHandleType: "unavailable"
    property string frameHandleError: ""

    function inspectFrameHandle(frame) {
        try {
            const member = frame ? frame.handleType : undefined
            const value = typeof member === "function"
                ? member.call(frame) : member
            if (typeof value !== "number") {
                frameHandleError = "QVideoFrame handle type is not exposed to QML"
                return
            }
            frameHandleType = value === 0 ? "no-handle"
                : value === 1 ? "rhi-texture" : "unknown-" + value
        } catch (exception) {
            frameHandleError = String(exception)
        }
    }

    function beginFrameMeasurement() {
        observedFrames = firstFrameReady ? 1 : 0
        measuringFrames = true
    }

    function endFrameMeasurement() {
        measuringFrames = false
        return observedFrames
    }

    width: 2
    height: 2

    VideoOutput {
        id: output
        anchors.fill: parent
        visible: true
    }

    MediaPlayer {
        id: player
        source: LocalUrl.fromPath(root.path)
        videoOutput: output
        loops: MediaPlayer.Infinite

        onMediaStatusChanged: {
            if (mediaStatus === MediaPlayer.LoadedMedia
                    || mediaStatus === MediaPlayer.BufferedMedia)
                play()
        }
    }

    Connections {
        target: output.videoSink
        enabled: !root.firstFrameReady
        function onVideoFrameChanged(frame) {
            root.inspectFrameHandle(frame)
            root.firstFrameReady = true
        }
    }


    Connections {
        target: output.videoSink
        enabled: root.measuringFrames
        function onVideoFrameChanged() { root.observedFrames += 1 }
    }

    Component.onCompleted: player.play()
    Component.onDestruction: player.stop()
}
