import QtQuick
import qs.services.wallpaper

Item {
    id: root

    required property string screenName
    required property string path
    property real renderScale: 1

    readonly property var media: WallpaperProbeService.recordFor(path)
    readonly property string kind: media.state === "ready"
        ? String(media.kind || "unsupported") : "unknown"
    readonly property var poster: WallpaperPosterService.recordFor(path)
    readonly property string state: path.length === 0 ? "empty"
        : media.state === "failed" || media.state === "unsupported" ? "error"
        : renderer.item ? renderer.item.state : "loading"
    readonly property string error: media.state === "failed"
            || media.state === "unsupported"
        ? String(media.error || "Unsupported wallpaper media")
        : renderer.item ? renderer.item.error : ""
    readonly property bool suspended: kind === "video" && renderer.item
        ? Boolean(renderer.item.suspended) : false
    readonly property string suspendedReason: suspended && renderer.item
        ? String(renderer.item.suspendedReason || "") : ""
    readonly property int suspendedPositionMs: suspended && renderer.item
        ? Number(renderer.item.suspendedPositionMs) || 0 : 0
    readonly property bool decoderEvicted: kind === "video" && renderer.item
        ? Boolean(renderer.item.decoderEvicted) : false
    readonly property bool decoderLoaded: kind === "video" && renderer.item
        ? Boolean(renderer.item.decoderLoaded) : false
    readonly property bool playbackActive: kind === "video" && renderer.item
        ? Boolean(renderer.item.playbackActive) : false

    function inspect() {
        if (path.length > 0)
            WallpaperProbeService.enqueue(path)
    }

    function preparePoster() {
        if (media.state === "ready" && media.kind === "video")
            WallpaperPosterService.request(media)
    }

    Component.onCompleted: inspect()
    onPathChanged: inspect()
    onMediaChanged: preparePoster()

    Loader {
        id: renderer
        anchors.fill: parent
        active: root.path.length > 0 && root.media.state === "ready"
            && (root.kind === "static" || root.kind === "video")
        sourceComponent: root.kind === "video" ? videoComponent : staticComponent
    }

    Component {
        id: staticComponent
        StaticWallpaper {
            path: root.path
            renderScale: root.renderScale
        }
    }

    Component {
        id: videoComponent
        VideoWallpaper {
            path: root.path
            screenName: root.screenName
            posterPath: root.poster.state === "ready" || root.poster.stale
                ? root.poster.posterPath : ""
        }
    }
}
