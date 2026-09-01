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

    function configure(nextGeneration, nextPath, nextMedia, nextBackend,
            nextScreenName, nextPosterPath, nextRenderScale) {
        generation = nextGeneration
        screenName = nextScreenName
        renderScale = nextRenderScale
        media = nextMedia
        posterPath = nextPosterPath
        path = nextPath
        backend = nextBackend
    }

    function updateContext(nextMedia, nextPosterPath, nextRenderScale) {
        media = nextMedia
        posterPath = nextPosterPath
        renderScale = nextRenderScale
    }

    function clear() {
        path = ""
        media = ({})
        backend = ""
        posterPath = ""
    }

    Loader {
        id: renderer
        anchors.fill: parent
        active: root.configured
        sourceComponent: root.backend === "video" ? videoComponent
            : root.backend === "animated-image"
                || root.backend === "animated-media" ? animatedComponent
            : root.backend === "static" ? staticComponent : null
    }

    Component {
        id: staticComponent
        StaticWallpaper { path: root.path; renderScale: root.renderScale }
    }

    Component {
        id: videoComponent
        VideoWallpaper {
            path: root.path
            screenName: root.screenName
            lifecycleKey: root.screenName + "." + root.slotKey
            posterPath: root.posterPath
        }
    }

    Component {
        id: animatedComponent
        AnimatedWallpaper {
            path: root.path
            media: root.media
            screenName: root.screenName
            posterPath: root.posterPath
            renderScale: root.renderScale
        }
    }
}
