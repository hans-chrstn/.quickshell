import QtQuick
import qs.services.power
import qs.services.session
import qs.services.wallpaper

Item {
    id: root

    required property string screenName

    readonly property bool occlusionKnown:
        WallpaperOcclusionService.known(screenName)
    readonly property bool occluded:
        WallpaperOcclusionService.covered(screenName)
    readonly property bool monitorPowerKnown:
        WallpaperMonitorPowerService.known(screenName)
    readonly property bool monitorPowered:
        WallpaperMonitorPowerService.powered(screenName)
    readonly property bool playbackRequested: occlusionKnown
        && monitorPowerKnown && !SessionLockService.locked
        && !PowerStateService.pauseRequested && monitorPowered && !occluded
    property bool playbackAllowed: false
    readonly property bool suspended: !playbackAllowed
    readonly property string suspendedReason: SessionLockService.locked
        ? "session-locked" : PowerStateService.pauseRequested ? "on-battery"
            : !occlusionKnown || !monitorPowerKnown ? "observing-display"
            : !monitorPowered ? "monitor-off"
            : occluded ? "window-covered"
                : !playbackAllowed ? "resuming" : ""

    function reconcile() {
        if (playbackRequested) {
            resumeTimer.restart()
        } else {
            resumeTimer.stop()
            playbackAllowed = false
        }
    }

    onPlaybackRequestedChanged: reconcile()

    Timer {
        id: resumeTimer
        interval: 250
        repeat: false
        onTriggered: {
            if (root.playbackRequested)
                root.playbackAllowed = true
        }
    }

    Component.onCompleted: {
        SessionLockService.acquire()
        WallpaperOcclusionService.acquire(screenName)
        WallpaperMonitorPowerService.acquire(screenName)
        reconcile()
    }

    Component.onDestruction: {
        SessionLockService.release()
        WallpaperOcclusionService.release(screenName)
        WallpaperMonitorPowerService.release(screenName)
    }
}
