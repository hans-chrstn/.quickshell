import QtQuick
import qs.core
import qs.components.media
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
    readonly property string rendererBackend:
        WallpaperRenderSupportService.rendererFor(record)
    readonly property bool animatedSupported:
        rendererBackend === "animated-image"
            || rendererBackend === "animated-media"
    readonly property bool selectable: state === "ready"
        && rendererBackend.length > 0
    property bool selected: false
    signal activated()

    radius: 12
    color: Design.surface
    border.width: selected ? 2 : 1
    border.color: selected ? Design.blue : Design.separator
    clip: true
    scale: tap.pressed && selectable ? 0.975 : 1

    Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
    Behavior on border.color { ColorAnimation { duration: 120 } }

    MediaThumbnail {
        id: preview
        anchors.fill: parent
        anchors.margins: root.selected ? 3 : 2
        record: root.record
        cornerRadius: Math.max(0, root.radius - anchors.margins)
    }

    Rectangle {
        anchors.fill: preview
        radius: Math.max(0, root.radius - preview.anchors.margins)
        color: "#52000000"
        visible: !preview.previewReady || hover.hovered
        Behavior on opacity { NumberAnimation { duration: 120 } }
    }

    Column {
        anchors.centerIn: parent
        spacing: 4
            visible: !preview.previewReady

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: {
                if (root.state === "queued" || root.state === "probing")
                    return "Inspecting"
                if (root.state === "failed") return "Unavailable"
                if (root.state === "unsupported") return "Unsupported"
                if (preview.poster.state === "queued"
                        || preview.poster.state === "checking"
                        || preview.poster.state === "generating") return "Preparing preview"
                if (preview.poster.state === "failed") return "Preview unavailable"
                if (root.kind === "animatedImage") return "Animated image"
                if (root.kind === "video") return "Video"
                return "Loading"
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
