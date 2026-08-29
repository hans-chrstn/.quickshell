import QtQuick
import QtQuick.Effects
import qs.core
import qs.services.wallpaper

Rectangle {
    id: root

    required property var record
    readonly property string path: String(record?.path || "")
    readonly property string extension: {
        const fileName = path.slice(path.lastIndexOf("/") + 1)
        const dot = fileName.lastIndexOf(".")
        return dot >= 0 && dot < fileName.length - 1
            ? fileName.slice(dot + 1).toLowerCase() : "media"
    }
    readonly property string state: String(record?.state || "unknown")
    readonly property string kind: String(record?.kind || "unsupported")
    readonly property bool selectable: state === "ready"
        && (kind === "static" || kind === "video")
    readonly property bool needsPoster: state === "ready" && kind !== "static"
    readonly property var poster: WallpaperPosterService.recordFor(path)
    readonly property bool posterReady: poster.posterPath.length > 0
        && (poster.state === "ready" || poster.stale)
    property bool selected: false
    signal activated()

    function requestPoster() {
        if (needsPoster)
            WallpaperPosterService.request(record)
    }

    Component.onCompleted: requestPoster()
    onRecordChanged: requestPoster()

    Connections {
        target: WallpaperProbeService
        function onCacheEntriesChanged() { root.requestPoster() }
    }

    radius: 12
    color: Design.surface
    border.width: selected ? 2 : 1
    border.color: selected ? Design.blue : Design.separator
    clip: true
    scale: tap.pressed && selectable ? 0.975 : 1

    Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
    Behavior on border.color { ColorAnimation { duration: 120 } }

    Image {
        id: preview
        anchors.fill: parent
        anchors.margins: root.selected ? 3 : 2
        visible: root.kind === "static" || root.posterReady
        source: "file://" + (root.kind === "static"
            ? root.path : root.poster.posterPath)
        sourceSize.width: Math.ceil(width * 1.5)
        sourceSize.height: Math.ceil(height * 1.5)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSpreadAtMin: 1
            maskThresholdMin: 0.5
            maskSource: ShaderEffectSource {
                sourceItem: Rectangle {
                    width: preview.width
                    height: preview.height
                    radius: Math.max(0, root.radius - preview.anchors.margins)
                    color: "white"
                }
            }
        }
    }

    Rectangle {
        anchors.fill: preview
        radius: Math.max(0, root.radius - preview.anchors.margins)
        color: "#52000000"
        visible: (!root.selectable && !root.posterReady)
            || preview.status !== Image.Ready || hover.hovered
        Behavior on opacity { NumberAnimation { duration: 120 } }
    }

    Column {
        anchors.centerIn: parent
        spacing: 4
        visible: (!root.selectable && !root.posterReady)
            || preview.status !== Image.Ready

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: {
                if (root.state === "queued" || root.state === "probing")
                    return "Inspecting"
                if (root.state === "failed") return "Unavailable"
                if (root.state === "unsupported") return "Unsupported"
                if (root.poster.state === "queued"
                        || root.poster.state === "checking"
                        || root.poster.state === "generating") return "Preparing preview"
                if (root.poster.state === "failed") return "Preview unavailable"
                if (root.kind === "animatedImage") return "Animated image"
                if (root.kind === "video") return "Video"
                return preview.status === Image.Error ? "Unavailable" : "Loading"
            }
            color: Design.textMuted
            font.family: Design.fontText
            font.pixelSize: 11
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.state === "ready" && !root.selectable
            text: record.width + "×" + record.height
                + (record.durationMs > 0
                    ? " · " + (record.durationMs / 1000).toFixed(1) + "s" : "")
            color: Design.textMuted
            opacity: 0.7
            font.family: Design.fontMono
            font.pixelSize: 9
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 7
        width: extensionLabel.implicitWidth + 12
        height: 18
        radius: 9
        visible: root.path.length > 0
        color: root.kind === "video" ? Design.blue : Design.surfaceRaised

        Text {
            id: extensionLabel
            anchors.centerIn: parent
            text: root.extension
            color: Design.text
            font.family: Design.fontText
            font.pixelSize: 8
            font.weight: Font.DemiBold
        }
    }

    Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 8
        width: 18
        height: 18
        radius: 9
        visible: root.selected
        color: Design.blue

        Text {
            anchors.centerIn: parent
            text: "✓"
            color: Design.text
            font.pixelSize: 11
            font.weight: Font.Bold
        }
    }

    HoverHandler { id: hover }
    TapHandler {
        id: tap
        enabled: root.selectable
        onTapped: root.activated()
    }
}
