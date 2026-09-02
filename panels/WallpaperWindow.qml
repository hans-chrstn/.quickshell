import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.panels.wallpaper
import qs.services.wallpaper

PanelWindow {
    id: root

    readonly property string screenName: screen?.name ?? ""
    property string retainedScreenName: screenName
    readonly property string scheduledWallpaperPath:
        WallpaperScheduledOverlayService.pathForScreen(retainedScreenName)
    readonly property string manualWallpaperPath:
        WallpaperAssignmentService.loaded
            ? WallpaperAssignmentService.wallpaperForScreen(
                retainedScreenName) : ""
    readonly property string wallpaperPath: scheduledWallpaperPath.length > 0
        ? scheduledWallpaperPath : manualWallpaperPath

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    color: "black"
    exclusiveZone: 0

    WlrLayershell.namespace: "inspire-wallpaper"
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Item {
        id: inputParkingTarget
        width: 0
        height: 0
    }

    mask: Region {
        item: inputParkingTarget
    }

    function retainScreenIdentity() {
        const nextName = String(screenName || "").trim()
        if (nextName.length === 0 || nextName === retainedScreenName)
            return
        if (retainedScreenName.length > 0)
            WallpaperRenderService.remove(retainedScreenName)
        retainedScreenName = nextName
    }

    WallpaperSurface {
        id: wallpaper
        anchors.fill: parent
        screenName: root.retainedScreenName
        path: root.wallpaperPath
        renderScale: root.screen?.devicePixelRatio ?? 1

        function reportStatus() {
            WallpaperRenderService.report(
                root.retainedScreenName, root.wallpaperPath,
                state, error, kind, {
                    suspended: suspended,
                    suspendedReason: suspendedReason,
                    suspendedPositionMs: suspendedPositionMs,
                    decoderEvicted: decoderEvicted,
                    decoderLoaded: decoderLoaded,
                    playbackActive: playbackActive,
                    transitionRunning: transitionRunning,
                    transitionReason: transitionReason,
                    retainedRendererCount: retainedRendererCount
                })
        }

        onStateChanged: reportStatus()
        onErrorChanged: reportStatus()
        onKindChanged: reportStatus()
        onPathChanged: reportStatus()
        onSuspendedChanged: reportStatus()
        onSuspendedReasonChanged: reportStatus()
        onSuspendedPositionMsChanged: if (suspended) reportStatus()
        onDecoderEvictedChanged: reportStatus()
        onDecoderLoadedChanged: reportStatus()
        onPlaybackActiveChanged: reportStatus()
        onTransitionRunningChanged: reportStatus()
        onTransitionReasonChanged: reportStatus()
        onRetainedRendererCountChanged: reportStatus()
    }

    onScreenNameChanged: {
        retainScreenIdentity()
        wallpaper.reportStatus()
    }
    Component.onCompleted: {
        retainedScreenName = screenName
        retainScreenIdentity()
        wallpaper.reportStatus()
    }
    Component.onDestruction:
        WallpaperRenderService.remove(retainedScreenName)
}
