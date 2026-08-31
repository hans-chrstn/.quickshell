import QtQuick
import qs.core

Item {
    id: root

    required property string path
    property real renderScale: 1
    property bool playbackAllowed: true

    readonly property string state: path.length === 0 ? "empty"
        : animation.status === AnimatedImage.Loading ? "loading"
        : animation.status === AnimatedImage.Ready ? "ready"
        : animation.status === AnimatedImage.Error ? "error" : "loading"
    readonly property string error: animation.status === AnimatedImage.Error
        ? "Animated wallpaper could not be decoded" : ""
    readonly property bool firstFrameReady:
        animation.status === AnimatedImage.Ready
    readonly property bool playbackActive: firstFrameReady
        && playbackAllowed && animation.playing
    readonly property int currentFrame: animation.currentFrame
    readonly property int frameCount: animation.frameCount

    AnimatedImage {
        id: animation
        anchors.fill: parent
        source: LocalUrl.fromPath(root.path)
        sourceSize.width: Math.ceil(width * root.renderScale)
        sourceSize.height: Math.ceil(height * root.renderScale)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        playing: root.playbackAllowed
        visible: status === AnimatedImage.Ready
    }
}
