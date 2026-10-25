import QtQuick
import qs.core

Rectangle {
    id: root

    required property string label
    property bool primary: false
    signal activated

    implicitWidth: labelText.implicitWidth + 22
    implicitHeight: 30
    radius: 10
    color: primary ? Theme.accent : (hover.hovered ? Theme.fillElevated : Theme.fillSubtle)
    border.width: primary ? 0 : 1
    border.color: Theme.separator
    scale: tap.pressed ? 0.97 : 1
    opacity: enabled ? 1 : 0.45

    Behavior on color {
        ColorAnimation {
            duration: 110
        }
    }
    Behavior on scale {
        NumberAnimation {
            duration: 80
            easing.type: Easing.OutCubic
        }
    }

    Text {
        id: labelText
        anchors.centerIn: parent
        text: root.label
        color: primary ? Theme.textPrimary : (hover.hovered ? Theme.textPrimary : Theme.textSecondary)
        font.family: Design.fontText
        font.pixelSize: 10
        font.weight: Font.Medium
    }

    HoverHandler {
        id: hover
    }
    TapHandler {
        id: tap
        enabled: root.enabled
        acceptedButtons: Qt.LeftButton
        onTapped: root.activated()
    }
}
