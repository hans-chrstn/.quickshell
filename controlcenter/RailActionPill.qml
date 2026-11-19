import QtQuick
import qs.core

Rectangle {
    id: root

    property string label: ""
    property bool highlighted: false
    property bool destructive: false
    signal activated

    implicitWidth: Math.max(Design.minimumTouchTarget, labelText.implicitWidth + Design.space24)
    implicitHeight: Design.minimumTouchTarget
    radius: height / 2
    color: destructive ? Theme.tint(Theme.danger) : highlighted ? Theme.tint(Theme.accent) : Theme.fillElevated
    border.color: destructive ? Theme.tintBorder(Theme.danger) : highlighted ? Theme.tintBorder(Theme.accent) : Theme.separator

    Text {
        id: labelText
        anchors.centerIn: parent
        text: root.label
        color: root.destructive ? Theme.danger : root.highlighted ? Theme.accent : Theme.textPrimary
        font.family: Design.fontText
        font.pixelSize: Design.typeLabel
        font.weight: Font.DemiBold
    }

    HoverHandler {
        id: hover
    }

    TapHandler {
        onTapped: root.activated()
    }

    Accessible.role: Accessible.Button
    Accessible.name: label

    Behavior on color {
        ColorAnimation {
            duration: Design.motionStateDuration
        }
    }
}
