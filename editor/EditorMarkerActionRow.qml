import QtQuick
import qs.components
import qs.core
import qs.services.wallpaper.projects

HighlightableSurface {
    id: root

    required property string markerId
    required property var action
    required property var descriptor

    implicitHeight: 44
    interactive: false
    baseColor: Theme.fillQuiet
    cornerRadius: 11

    CompactBadge {
        id: actionBadge
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        text: root.descriptor.badge
    }

    Column {
        anchors.left: actionBadge.right
        anchors.leftMargin: 8
        anchors.right: removeButton.left
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1

        Text {
            width: parent.width
            text: root.descriptor.label
            color: Theme.textPrimary
            font.family: Design.fontText
            font.pixelSize: 10
            font.weight: Font.Medium
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            text: root.action.target ? root.action.target : "Not configured"
            color: Theme.textSecondary
            font.family: Design.fontText
            font.pixelSize: 8
            elide: Text.ElideRight
        }
    }

    GlyphButton {
        id: removeButton
        anchors.right: parent.right
        anchors.rightMargin: 7
        anchors.verticalCenter: parent.verticalCenter
        glyph: "close"
        accessibleName: "Remove action"
        toolTip: "Remove action"
        onActivated: WallpaperTimelineService.markerActionEdit(root.markerId, root.action.id, "remove", null)
    }
}
