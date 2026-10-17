import QtQuick
import qs.services.config
import qs.services.display
import qs.services.power
import qs.services.session
import qs.services.wallpaper

Item {
    id: root

    required property string screenName
    property bool observe: true

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
        && !WallpaperPresentationService.editorActive
        && (!ConfigService.pauseWallpaperWhenIdle
            || DisplayActivityService.desktopActive)
        && !PowerStateService.pauseRequested && monitorPowered && !occluded
    property bool playbackAllowed: false
    readonly property bool suspended: !playbackAllowed
    readonly property string suspendedReason: SessionLockService.locked
        ? "session-locked" : WallpaperPresentationService.editorActive
            ? "editor-open" : ConfigService.pauseWallpaperWhenIdle
                && DisplayActivityService.idle ? "user-idle"
        : PowerStateService.pauseRequested ? "on-battery"
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

    Connections {
        target: WallpaperPresentationService
        function onEditorActiveChanged() { root.reconcile() }
    }

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
        if (!root.observe)
            return
        SessionLockService.acquire()
        DisplayActivityService.acquire(screenName)
        WallpaperOcclusionService.acquire(screenName)
        WallpaperMonitorPowerService.acquire(screenName)
        reconcile()
    }

    Component.onDestruction: {
        if (!root.observe)
            return
        SessionLockService.release()
        DisplayActivityService.release(screenName)
        WallpaperOcclusionService.release(screenName)
        WallpaperMonitorPowerService.release(screenName)
    }
}
