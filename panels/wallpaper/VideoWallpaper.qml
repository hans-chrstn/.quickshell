import QtQuick
import QtMultimedia
import qs.services.session

Item {
    id: root

    required property string path
    property string posterPath: ""
    property bool playingAllowed: !SessionLockService.locked
    property bool firstFrameReady: false
    property int suspendedPositionMs: 0

    readonly property string state: player.error !== MediaPlayer.NoError
        ? "error" : firstFrameReady ? "ready" : "loading"
    readonly property string error: player.error !== MediaPlayer.NoError
        ? String(player.errorString || "Video wallpaper could not be decoded") : ""
    readonly property bool suspended: !playingAllowed

    function syncPlayback() {
        if (player.source == "")
            return
        if (playingAllowed)
            player.play()
        else {
            suspendedPositionMs = player.position
            player.pause()
        }
    }

    onPlayingAllowedChanged: syncPlayback()

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

    Component.onCompleted: {
        SessionLockService.acquire()
        syncPlayback()
    }
    Component.onDestruction: SessionLockService.release()
}
