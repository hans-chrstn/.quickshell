import QtQuick
import qs.core
import qs.services.wallpaper

Item {
    id: root

    required property string path
    required property var media
    required property string screenName
    property string posterPath: ""
    property real renderScale: 1

    readonly property string backend:
        WallpaperRenderSupportService.animatedBackendFor(media)
    readonly property string state: backend.length === 0 ? "error"
        : renderer.item ? renderer.item.state : "loading"
    readonly property string error: backend.length === 0
        ? "Animated wallpaper format is unavailable on this Qt stack"
        : renderer.item ? renderer.item.error : ""
    readonly property bool firstFrameReady:
        Boolean(renderer.item?.firstFrameReady)
    readonly property bool posterReady: posterImage.status === Image.Ready
    readonly property bool visualReady: firstFrameReady || posterReady
    readonly property bool playbackActive:
        Boolean(renderer.item?.playbackActive
            ?? renderer.item?.actuallyPlaying)
    readonly property bool suspended: playbackPolicy.suspended
    readonly property string suspendedReason:
        playbackPolicy.suspendedReason

    WallpaperPlaybackPolicy {
        id: playbackPolicy
        screenName: root.screenName
    }

    Image {
        id: posterImage
        anchors.fill: parent
        source: LocalUrl.fromPath(root.posterPath)
        sourceSize.width: Math.ceil(width * root.renderScale)
        sourceSize.height: Math.ceil(height * root.renderScale)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: !root.firstFrameReady && status === Image.Ready
    }

    Loader {
        id: renderer
        anchors.fill: parent
        active: root.backend.length > 0
        sourceComponent: root.backend === "image"
            ? imageComponent : mediaComponent
    }

    Component {
        id: imageComponent
        AnimatedImageWallpaper {
            path: root.path
            renderScale: root.renderScale
            playbackAllowed: playbackPolicy.playbackAllowed
        }
    }

    Component {
        id: mediaComponent
        VideoDecoder {
            path: root.path
            playbackAllowed: playbackPolicy.playbackAllowed
        }
    }
}
