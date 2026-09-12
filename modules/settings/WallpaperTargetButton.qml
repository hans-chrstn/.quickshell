import QtQuick
import qs.core

Rectangle {
    id: root

    required property string label
    property bool selected: false
    signal activated()

    implicitWidth: labelText.implicitWidth + 24
    implicitHeight: 32
    radius: 10
    color: selected ? Design.blue : (hover.hovered ? Design.surfaceRaised : Design.surface)
    border.width: selected ? 0 : 1
    border.color: Design.separator
    scale: tap.pressed ? 0.96 : 1

    Behavior on color { ColorAnimation { duration: 120 } }
    Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }

    Text {
        id: labelText
        anchors.centerIn: parent
        text: root.label
        color: root.selected ? Design.text : Design.textMuted
        font.family: Design.fontText
        font.pixelSize: 11
        font.weight: Font.Medium
    }

    HoverHandler { id: hover }
    TapHandler {
        id: tap
        onTapped: root.activated()
    }
}
