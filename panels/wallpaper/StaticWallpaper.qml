import QtQuick
import qs.core

Item {
    id: root

    required property string path
    property real renderScale: 1

    readonly property string state: path.length === 0 ? "empty"
        : image.status === Image.Loading ? "loading"
        : image.status === Image.Ready ? "ready"
        : image.status === Image.Error ? "error" : "loading"
    readonly property string error: image.status === Image.Error
        ? "Wallpaper could not be decoded" : ""
    readonly property bool visualReady: image.status === Image.Ready

    Image {
        id: image
        anchors.fill: parent
        source: LocalUrl.fromPath(root.path)
        sourceSize.width: Math.ceil(width * root.renderScale)
        sourceSize.height: Math.ceil(height * root.renderScale)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: status === Image.Ready
    }
}
