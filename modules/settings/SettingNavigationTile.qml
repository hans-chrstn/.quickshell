import QtQuick
import QtQuick.Layouts
import qs.components
import qs.core

Rectangle {
    id: root

    required property string title
    required property string description
    signal activated()

    implicitHeight: 52
    radius: 10
    color: hover.hovered ? Design.surfaceRaised : Design.surface
    border.width: 1
    border.color: hover.hovered ? Design.glassHighlight : Design.separator
    scale: tap.pressed ? 0.985 : 1

    Behavior on color { ColorAnimation { duration: 110 } }
    Behavior on border.color { ColorAnimation { duration: 110 } }
    Behavior on scale {
        NumberAnimation { duration: 80; easing.type: Easing.OutCubic }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        spacing: 12

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            Text {
                text: root.title
                color: Design.text
                font.family: Design.fontText
                font.pixelSize: 12
                font.weight: Font.DemiBold
            }

            Text {
                text: root.description
                color: Design.textMuted
                font.family: Design.fontText
                font.pixelSize: 9
            }
        }

        IslandGlyph {
            name: "chevronRight"
            glyphColor: hover.hovered ? Design.text : Design.textMuted
            Layout.preferredWidth: 17
            Layout.preferredHeight: 17
            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
        }
    }

    HoverHandler { id: hover }
    TapHandler {
        id: tap
        acceptedButtons: Qt.LeftButton
        onTapped: root.activated()
    }
}
