import QtQuick
import Quickshell
import Quickshell.Wayland
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

    Image {
        id: wallpaper

        anchors.fill: parent
        source: root.wallpaperPath.length > 0
            ? "file://" + root.wallpaperPath : ""
        sourceSize.width: Math.ceil(root.width * (root.screen?.devicePixelRatio ?? 1))
        sourceSize.height: Math.ceil(root.height * (root.screen?.devicePixelRatio ?? 1))
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: status === Image.Ready

        function reportStatus() {
            let state = "empty"
            let error = ""
            if (root.wallpaperPath.length > 0) {
                if (status === Image.Loading)
                    state = "loading"
                else if (status === Image.Ready)
                    state = "ready"
                else if (status === Image.Error) {
                    state = "error"
                    error = "Wallpaper could not be decoded"
                }
            }
            WallpaperRenderService.report(
                root.screenName, root.wallpaperPath, state, error)
        }

        onStatusChanged: reportStatus()
        onSourceChanged: reportStatus()
    }

    onScreenNameChanged: wallpaper.reportStatus()
    Component.onCompleted: wallpaper.reportStatus()
    Component.onDestruction: WallpaperRenderService.remove(screenName)
}
