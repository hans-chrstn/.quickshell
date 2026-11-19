import QtQuick
import qs.components.media
import qs.core
import qs.services.wallpaper

Item {
    id: root

    required property string path
    property string screenName: ""
    property real renderScale: 1
    readonly property var placement: WallpaperAssignmentService.placementFor("desktop", screenName, path)

    readonly property string state: path.length === 0 ? "empty" : image.status === Image.Loading ? "loading" : image.status === Image.Ready ? "ready" : image.status === Image.Error ? "error" : "loading"
    readonly property string error: image.status === Image.Error ? "Wallpaper could not be decoded" : ""
    readonly property bool visualReady: image.status === Image.Ready

    WallpaperPlacementImage {
        id: image
        anchors.fill: parent
        path: root.path
        placement: root.placement
        renderScale: root.renderScale
    }
}
