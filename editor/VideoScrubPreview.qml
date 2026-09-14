import QtQuick
import QtMultimedia
import Quickshell
import qs.core

Item {
    id: root

    required property string path
    required property int positionMs
    property bool active: false
    readonly property bool visualReady: firstFrameReady
    property bool firstFrameReady: false
    property bool requestPending: false

    function requestSeek() {
        requestPending = true
        if (!requestTimer.running)
            requestTimer.start()
    }

    onPositionMsChanged: {
        if (root.active)
            root.requestSeek()
    }

    onActiveChanged: {
        if (!root.active) {
            root.requestPending = false
            player.pause()
        } else {
            root.requestSeek()
        }
    }

    Timer {
        id: requestTimer
        interval: 100
        repeat: true
        running: root.active
        onTriggered: {
            if (!root.requestPending)
                return
            root.requestPending = false
            player.pause()
            player.position = root.positionMs
        }
    }

    VideoOutput {
        id: output
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectCrop
        visible: root.firstFrameReady
    }

    MediaPlayer {
        id: player
        source: root.path.length > 0 ? LocalUrl.fromPath(root.path) : ""
        videoOutput: output
        loops: MediaPlayer.Infinite
        onSourceChanged: {
            root.firstFrameReady = false
            root.requestSeek()
        }
        onMediaStatusChanged: {
            if (mediaStatus === MediaPlayer.LoadedMedia
                    || mediaStatus === MediaPlayer.BufferedMedia) {
                player.pause()
                root.requestSeek()
            }
        }
    }

    Connections {
        target: output.videoSink
        enabled: !root.firstFrameReady
        function onVideoFrameChanged() { root.firstFrameReady = true }
    }

}
