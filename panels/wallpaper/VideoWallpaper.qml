import QtQuick
import QtMultimedia

Item {
    id: root

    required property string path
    property string posterPath: ""
    property bool firstFrameReady: false

    readonly property string state: player.error !== MediaPlayer.NoError
        ? "error" : firstFrameReady ? "ready" : "loading"
    readonly property string error: player.error !== MediaPlayer.NoError
        ? String(player.errorString || "Video wallpaper could not be decoded") : ""

    Image {
        anchors.fill: parent
        source: root.posterPath.length > 0 ? "file://" + root.posterPath : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: !root.firstFrameReady && status === Image.Ready
    }

    VideoOutput {
        id: output
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectCrop
        visible: root.firstFrameReady
    }

    MediaPlayer {
        id: player
        source: root.path.length > 0 ? "file://" + root.path : ""
        videoOutput: output
        loops: MediaPlayer.Infinite

        onSourceChanged: {
            root.firstFrameReady = false
            if (source != "") play()
        }
        onMediaStatusChanged: {
            if (mediaStatus === MediaPlayer.LoadedMedia
                    || mediaStatus === MediaPlayer.BufferedMedia)
                play()
        }
    }

    Connections {
        target: output.videoSink
        function onVideoFrameChanged() { root.firstFrameReady = true }
    }

    Component.onCompleted: if (player.source != "") player.play()
}
