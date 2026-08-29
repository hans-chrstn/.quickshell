import QtQuick
import QtMultimedia

Item {
    id: root

    required property string path
    required property bool playbackAllowed
    property int resumePositionMs: 0
    property bool resumeApplied: false
    property bool firstFrameReady: false

    readonly property int currentPositionMs: Number(player.position) || 0
    readonly property string state: player.error !== MediaPlayer.NoError
        ? "error" : firstFrameReady ? "ready" : "loading"
    readonly property string error: player.error !== MediaPlayer.NoError
        ? String(player.errorString || "Video wallpaper could not be decoded") : ""

    signal positionCaptured(int positionMs)

    function captureAndPause() {
        const position = currentPositionMs
        positionCaptured(position)
        player.pause()
    }

    function syncPlayback() {
        if (player.source == "")
            return
        if (!playbackAllowed) {
            captureAndPause()
            return
        }
        if ((player.mediaStatus === MediaPlayer.LoadedMedia
                || player.mediaStatus === MediaPlayer.BufferedMedia)
                && !resumeApplied) {
            if (resumePositionMs > 0)
                player.position = resumePositionMs
            resumeApplied = true
        }
        player.play()
    }

    onPlaybackAllowedChanged: syncPlayback()

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
            root.resumeApplied = false
            root.firstFrameReady = false
            root.syncPlayback()
        }
        onMediaStatusChanged: {
            if (mediaStatus === MediaPlayer.LoadedMedia
                    || mediaStatus === MediaPlayer.BufferedMedia)
                root.syncPlayback()
        }
    }

    Connections {
        target: output.videoSink
        function onVideoFrameChanged() { root.firstFrameReady = true }
    }

    Component.onCompleted: syncPlayback()
}
