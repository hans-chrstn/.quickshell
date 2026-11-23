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
    activeFocusOnTab: enabled
    opacity: enabled ? 1 : 0.4
    radius: Design.radiusControl
    color: destructive ? Theme.tint(Theme.danger) : highlighted ? Theme.tint(Theme.accent) : hover.hovered ? Theme.fillStrong : Theme.fillElevated
    border.color: activeFocus ? Theme.focusRing : destructive ? Theme.tintBorder(Theme.danger) : highlighted ? Theme.tintBorder(Theme.accent) : Theme.separator

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
        enabled: root.enabled
        onTapped: root.activated()
    }

    Keys.onPressed: event => {
        if (root.enabled && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space)) {
            root.activated();
            event.accepted = true;
        }
    }

    Accessible.role: Accessible.Button
    Accessible.name: label

    Behavior on color {
        ColorAnimation {
            duration: Design.motionStateDuration
        }
    }

    Behavior on opacity {
        NumberAnimation {
            duration: Design.motionStateDuration
        }
    }
}
