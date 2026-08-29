import QtQuick
import qs.services.power
import qs.services.session
import qs.services.wallpaper

Item {
    id: root

    required property string path
    required property string screenName
    property string posterPath: ""
    readonly property bool occluded: WallpaperOcclusionService.covered(screenName)
    readonly property bool monitorPowered:
        WallpaperMonitorPowerService.powered(screenName)
    readonly property bool playbackRequested: !SessionLockService.locked
        && !PowerStateService.pauseRequested && monitorPowered && !occluded
    property bool playingAllowed: false
    property bool firstFrameReady: false
    property int suspendedPositionMs: 0
    property bool decoderRetained: true
    readonly property int decoderEvictionDelayMs: 30000
    readonly property bool decoderEvicted: !decoderRetained
    readonly property bool decoderLoaded: decoder.item !== null
    readonly property bool playbackActive: playingAllowed && decoderLoaded

    readonly property string state: decoder.item ? decoder.item.state
        : decoderRetained ? "loading" : "ready"
    readonly property string error: decoder.item ? decoder.item.error : ""
    readonly property bool suspended: !playingAllowed
    readonly property string suspendedReason: SessionLockService.locked
        ? "session-locked" : PowerStateService.pauseRequested ? "on-battery"
            : !monitorPowered ? "monitor-off"
            : occluded ? "window-covered"
                : !playingAllowed ? "resuming" : ""

    function reconcilePlaybackRequest() {
        if (playbackRequested) {
            resumeTimer.restart()
        } else {
            resumeTimer.stop()
            playingAllowed = false
            applyPlaybackPolicy()
        }
    }

    function applyPlaybackPolicy() {
        if (playingAllowed) {
            evictionTimer.stop()
            if (!decoderRetained) {
                firstFrameReady = false
                decoderRetained = true
            }
        } else {
            if (decoder.item)
                decoder.item.captureAndPause()
            evictionTimer.restart()
        }
    }

    onPlaybackRequestedChanged: reconcilePlaybackRequest()
    onPlayingAllowedChanged: applyPlaybackPolicy()

    Timer {
        id: resumeTimer
        interval: 250
        repeat: false
        onTriggered: {
            if (root.playbackRequested)
                root.playingAllowed = true
        }
    }

    Image {
        anchors.fill: parent
        source: root.posterPath.length > 0 ? "file://" + root.posterPath : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: !root.firstFrameReady && status === Image.Ready
    }

    Loader {
        id: decoder
        anchors.fill: parent
        active: root.decoderRetained
        sourceComponent: decoderComponent
    }

    Component {
        id: decoderComponent
        VideoDecoder {
            path: root.path
            playbackAllowed: root.playingAllowed
            resumePositionMs: root.suspendedPositionMs
            onPositionCaptured: positionMs => {
                root.suspendedPositionMs = positionMs
            }
            onFirstFrameReadyChanged: {
                root.firstFrameReady = firstFrameReady
            }
        }
    }

    Timer {
        id: evictionTimer
        interval: root.decoderEvictionDelayMs
        repeat: false
        onTriggered: {
            if (root.playingAllowed || !root.decoderRetained)
                return
            if (decoder.item)
                decoder.item.captureAndPause()
            root.firstFrameReady = false
            root.decoderRetained = false
        }
    }

    Component.onCompleted: {
        SessionLockService.acquire()
        WallpaperOcclusionService.acquire(screenName)
        WallpaperMonitorPowerService.acquire(screenName)
        reconcilePlaybackRequest()
    }
    Component.onDestruction: {
        SessionLockService.release()
        WallpaperOcclusionService.release(screenName)
        WallpaperMonitorPowerService.release(screenName)
    }
}
