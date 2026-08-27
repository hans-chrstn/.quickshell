import QtQuick
import qs.core
import qs.components

Item {
    id: root

    required property string icon
    required property string label
    signal activated()

    implicitWidth: 94
    implicitHeight: 32

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: hover.hovered ? Design.surfaceRaised : "transparent"
    }

    Row {
        anchors.centerIn: parent
        spacing: 7

        IslandGlyph {
            anchors.verticalCenter: parent.verticalCenter
            name: root.icon
            glyphColor: hover.hovered ? Design.text : Design.textMuted
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.label
            color: hover.hovered ? Design.text : Design.textMuted
            font.family: Design.fontText
            font.pixelSize: 12
            font.weight: Font.Medium
        }
    }

    HoverHandler { id: hover }
    TapHandler {
        acceptedButtons: Qt.LeftButton
        gesturePolicy: TapHandler.DragThreshold
        grabPermissions: PointerHandler.ApprovesTakeOverByAnything
        onTapped: root.activated()
    }
}
