import QtQuick
import QtQuick.Layouts
import qs.core

HighlightableSurface {
    id: root

    required property string title
    property string description: ""
    property string badgeText: ""
    signal activated

    implicitHeight: description.length > 0 ? 48 : 38
    interactive: true
    baseColor: Theme.fillSubtle
    cornerRadius: 11
    accessibleName: title
    onSurfaceActivated: root.activated()

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 8

        CompactBadge {
            visible: root.badgeText.length > 0
            text: root.badgeText
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            Text {
                Layout.fillWidth: true
                text: root.title
                color: Theme.textPrimary
                font.family: Design.fontText
                font.pixelSize: 10
                font.weight: Font.Medium
                elide: Text.ElideRight
            }

            Text {
                visible: root.description.length > 0
                Layout.fillWidth: true
                text: root.description
                color: Theme.textSecondary
                font.family: Design.fontText
                font.pixelSize: 8
                elide: Text.ElideRight
            }
        }

        IslandGlyph {
            name: "chevronRight"
            glyphColor: Theme.textSecondary
        }
    }
}
