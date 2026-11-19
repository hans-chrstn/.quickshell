import QtQuick
import qs.components
import qs.components.media
import qs.core
import qs.services.wallpaper

HighlightableSurface {
    id: root

    required property string title
    required property string path
    property string subtitle: ""
    property string placementTarget: "desktop"
    property string placementScreenName: ""
    signal activated

    readonly property var record: WallpaperProbeService.recordFor(path)

    function ensurePreview() {
        if (path.length > 0 && (record.state === "unknown" || record.state === "cancelled"))
            WallpaperProbeService.enqueue(path);
    }

    accentColor: Theme.accent
    baseColor: Theme.fillSubtle
    cornerRadius: Design.radiusGrouped
    clip: true
    onSurfaceActivated: activated()

    Component.onCompleted: ensurePreview()
    onPathChanged: ensurePreview()

    Connections {
        target: WallpaperProbeService
        function onRecordsChanged() {
            Qt.callLater(root.ensurePreview);
        }
    }

    WallpaperPlacementImage {
        anchors.fill: parent
        anchors.margins: 2
        visible: root.record.kind === "static"
        path: visible ? root.path : ""
        cornerRadius: Math.max(0, root.cornerRadius - 2)
        placement: WallpaperAssignmentService.placementFor(root.placementTarget, root.placementScreenName, root.path)
    }

    Loader {
        anchors.fill: parent
        anchors.margins: 2
        active: root.record.kind !== "static"
        sourceComponent: MediaThumbnail {
            record: root.record
            cornerRadius: Math.max(0, root.cornerRadius - 2)
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: root.cornerRadius
        color: Theme.scrim
        opacity: root.path.length > 0 ? 0.32 : 0.72
    }

    IslandGlyph {
        anchors.centerIn: parent
        width: 30
        height: 30
        visible: root.path.length === 0
        name: "plus"
        glyphColor: Theme.textSecondary
    }

    Column {
        anchors.left: parent.left
        anchors.leftMargin: Design.space12
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Design.space8
        spacing: 2

        Text {
            text: root.title
            color: Theme.textPrimary
            font.family: Design.fontText
            font.pixelSize: Design.typeBody
            font.weight: Font.DemiBold
        }

        Text {
            visible: root.subtitle.length > 0
            text: root.subtitle
            color: Theme.textSecondary
            font.family: Design.fontText
            font.pixelSize: Design.typeLabel
        }
    }
}
