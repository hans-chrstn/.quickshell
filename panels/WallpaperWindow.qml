import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.panels.wallpaper
import qs.services.wallpaper

PanelWindow {
    id: root

    readonly property string screenName: screen?.name ?? ""
    readonly property string wallpaperPath:
        WallpaperAssignmentService.loaded
            ? WallpaperAssignmentService.wallpaperForScreen(screenName) : ""

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

    WallpaperSurface {
        id: wallpaper
        anchors.fill: parent
        screenName: root.screenName
        path: root.wallpaperPath
        renderScale: root.screen?.devicePixelRatio ?? 1

        function reportStatus() {
            WallpaperRenderService.report(
                root.screenName, root.wallpaperPath, state, error, kind)
        }

        onStateChanged: reportStatus()
        onKindChanged: reportStatus()
        onPathChanged: reportStatus()
    }

    onScreenNameChanged: wallpaper.reportStatus()
    Component.onCompleted: wallpaper.reportStatus()
    Component.onDestruction: WallpaperRenderService.remove(screenName)
}
