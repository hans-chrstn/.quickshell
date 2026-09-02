import QtQuick

Item {
    id: root

    property string slotKey: "slot"
    property int generation: 0
    property string path: ""
    property var media: ({})
    property string backend: ""
    property string screenName: ""
    property string posterPath: ""
    property real renderScale: 1

    readonly property bool configured: path.length > 0 && backend.length > 0
    readonly property string state: configured
        ? renderer.item?.state ?? "loading" : "empty"
    readonly property string error: renderer.item?.error ?? ""
    readonly property bool visualReady: Boolean(
        renderer.item?.visualReady ?? (state === "ready"))
    readonly property bool suspended: Boolean(renderer.item?.suspended)
    readonly property string suspendedReason:
        String(renderer.item?.suspendedReason || "")
    readonly property int suspendedPositionMs:
        Number(renderer.item?.suspendedPositionMs) || 0
    readonly property bool decoderEvicted: Boolean(renderer.item?.decoderEvicted)
    readonly property bool decoderLoaded: Boolean(renderer.item?.decoderLoaded)
    readonly property bool playbackActive: Boolean(renderer.item?.playbackActive)

    function sourceForBackend() {
        if (backend === "video")
            return Qt.resolvedUrl("VideoWallpaper.qml")
        if (backend === "animated-image" || backend === "animated-media")
            return Qt.resolvedUrl("AnimatedWallpaper.qml")
        if (backend === "static")
            return Qt.resolvedUrl("StaticWallpaper.qml")
        return ""
    }

    function initialProperties() {
        if (backend === "video") {
            return {
                path: root.path,
                screenName: root.screenName,
                lifecycleKey: root.screenName + "." + root.slotKey,
                posterPath: root.posterPath
            }
        }
        if (backend === "animated-image" || backend === "animated-media") {
            return {
                path: root.path,
                media: root.media,
                screenName: root.screenName,
                posterPath: root.posterPath,
                renderScale: root.renderScale
            }
        }
        if (backend === "static")
            return { path: root.path, renderScale: root.renderScale }
        return ({})
    }

    function loadRenderer() {
        const source = sourceForBackend()
        if (!configured || String(source).length === 0) {
            renderer.source = ""
            return
        }
        renderer.setSource(source, initialProperties())
    }

    function syncRendererContext() {
        const item = renderer.item
        if (!item)
            return
        item.path = path
        if (backend === "video") {
            item.screenName = screenName
            item.lifecycleKey = screenName + "." + slotKey
            item.posterPath = posterPath
        } else if (backend === "animated-image"
                || backend === "animated-media") {
            item.media = media
            item.screenName = screenName
            item.posterPath = posterPath
            item.renderScale = renderScale
        } else if (backend === "static") {
            item.renderScale = renderScale
        }
    }

    function configure(nextGeneration, nextPath, nextMedia, nextBackend,
            nextScreenName, nextPosterPath, nextRenderScale) {
        generation = nextGeneration
        screenName = nextScreenName
        renderScale = nextRenderScale
        media = nextMedia
        posterPath = nextPosterPath
        path = nextPath
        backend = nextBackend
        loadRenderer()
    }

    function updateContext(nextMedia, nextPosterPath, nextRenderScale) {
        media = nextMedia
        posterPath = nextPosterPath
        renderScale = nextRenderScale
        syncRendererContext()
    }

    function clear() {
        renderer.source = ""
        path = ""
        media = ({})
        backend = ""
        posterPath = ""
    }

    Loader {
        id: renderer
        anchors.fill: parent
        onLoaded: root.syncRendererContext()
    }
}
