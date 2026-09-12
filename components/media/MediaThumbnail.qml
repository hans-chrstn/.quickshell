import QtQuick
import QtQuick.Effects
import qs.core
import qs.services.wallpaper

Item {
    id: root

    required property var record
    property real cornerRadius: 10
    property string preferredPreviewPath: ""
    property bool posterRequestsEnabled: true
    readonly property string path: String(record?.path || "")
    readonly property string kind: String(record?.kind || "unsupported")
    readonly property bool needsPoster: record?.state === "ready"
        && kind !== "static" && preferredPreviewPath.length === 0
        && posterRequestsEnabled
    readonly property var poster: WallpaperPosterService.recordFor(path)
    readonly property bool posterReady: poster.posterPath.length > 0
        && (poster.state === "ready" || poster.stale)
    readonly property bool previewReady: image.status === Image.Ready

    function requestPoster() {
        if (needsPoster) WallpaperPosterService.request(record)
    }

    Component.onCompleted: requestPoster()
    onRecordChanged: requestPoster()

    Connections {
        target: WallpaperProbeService
        function onCacheEntriesChanged() { root.requestPoster() }
    }

    Image {
        id: image
        anchors.fill: parent
        visible: source.toString().length > 0
        source: root.preferredPreviewPath.length > 0
            ? LocalUrl.fromPath(root.preferredPreviewPath)
            : root.kind === "static" ? LocalUrl.fromPath(root.path)
            : root.posterReady ? LocalUrl.fromPath(root.poster.posterPath) : ""
        sourceSize.width: Math.max(1, Math.ceil(width * 1.5))
        sourceSize.height: Math.max(1, Math.ceil(height * 1.5))
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSpreadAtMin: 1
            maskThresholdMin: 0.5
            maskSource: ShaderEffectSource {
                sourceItem: Rectangle {
                    width: image.width
                    height: image.height
                    radius: root.cornerRadius
                    color: "white"
                }
            }
        }
    }
}
