import QtQuick
import qs.components.lifecycle
import qs.services.wallpaper

Item {
    id: root

    required property string screenName
    required property string path
    property real renderScale: 1

    readonly property var media: WallpaperProbeService.recordFor(path)
    readonly property string kind: media.state === "ready"
        ? String(media.kind || "unsupported") : "unknown"
    readonly property string rendererBackend:
        WallpaperRenderSupportService.rendererFor(media)
    readonly property bool animatedSupported:
        rendererBackend === "animated-image"
            || rendererBackend === "animated-media"
    readonly property bool motionWallpaper:
        kind === "video" || animatedSupported
    readonly property var poster: WallpaperPosterService.recordFor(path)
    readonly property string state: path.length === 0
        ? "empty" : renderer.item?.state ?? "loading"
    readonly property string error: renderer.item?.error ?? ""
    readonly property bool suspended: Boolean(renderer.item?.suspended)
    readonly property string suspendedReason:
        String(renderer.item?.suspendedReason || "")
    readonly property int suspendedPositionMs:
        Number(renderer.item?.suspendedPositionMs) || 0
    readonly property bool decoderEvicted:
        Boolean(renderer.item?.decoderEvicted)
    readonly property bool decoderLoaded:
        Boolean(renderer.item?.decoderLoaded)
    readonly property bool playbackActive:
        Boolean(renderer.item?.playbackActive)

    function inspect() {
        if (path.length > 0)
            WallpaperProbeService.enqueue(path)
    }

    function preparePoster() {
        if (media.state === "ready" && motionWallpaper)
            WallpaperPosterService.request(media)
    }

    Component.onCompleted: {
        inspect()
        Qt.callLater(preparePoster)
    }
    onPathChanged: inspect()
    onMediaChanged: Qt.callLater(preparePoster)

    Connections {
        target: WallpaperProbeService
        function onCacheEntriesChanged() { Qt.callLater(root.preparePoster) }
    }

    LifecycleLoader {
        id: renderer
        anchors.fill: parent
        resourceId: "wallpaper.renderer." + root.screenName
        owner: "wallpaper.surface." + root.screenName
        restorationSource: "WallpaperAssignmentService and probe record"
        classification: "expensive"
        requestedActive: root.path.length > 0
        retentionReason: requestedActive
            ? "assigned-" + root.kind : ""
        evictionReason: requestedActive ? ""
            : root.path.length === 0 ? "no-assignment"
            : root.media.state !== "ready" ? "media-unavailable"
            : "unsupported-renderer"
        sourceComponent: rendererHostComponent
    }

    Component {
        id: rendererHostComponent
        WallpaperRendererHost {
            targetPath: root.path
            targetMedia: root.media
            targetBackend: root.rendererBackend
            screenName: root.screenName
            targetPosterPath: root.poster.state === "ready" || root.poster.stale
                ? root.poster.posterPath : ""
            renderScale: root.renderScale
        }
    }
}
