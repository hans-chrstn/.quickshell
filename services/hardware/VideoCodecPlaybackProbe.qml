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
        function onVideoFrameChanged() { root.firstFrameReady = true }
    }

    Component.onCompleted: player.play()
    Component.onDestruction: player.stop()
}
