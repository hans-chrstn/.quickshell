import QtQuick
import QtQuick.Controls
import qs.core

FocusScope {
    id: root

    property bool selected: false
    property bool selectionFillEnabled: true
    property bool toggleable: false
    property bool activationEnabled: true
    property bool interactive: true
    property bool hoverEnabled: true
    property bool focusOnActivate: true
    property bool externalFocus: false
    property bool pressScaleEnabled: true
    property color accentColor: Theme.selection
    property color baseColor: Theme.interactionRest
    property color hoverColor: Theme.interactionHover
    property color pressedColor: Theme.interactionPressed
    property color selectedColor: Theme.interactionSelected
    property color outlineColor: Theme.separatorStrong
    property bool accentSelectedOutline: false
    property real cornerRadius: Design.radiusControl
    property real controlInset: 0
    property real pressedScale: 0.985
    readonly property bool hovered: hoverHandler.hovered
    readonly property bool pressed: primaryTap.pressed
    readonly property bool highlighted: selected || externalFocus || hovered || activeFocus
    readonly property color stateColor: pressed ? pressedColor : selected && selectionFillEnabled ? selectedColor : hovered || externalFocus ? hoverColor : baseColor
    signal triggered(var modifiers)
    signal decreaseRequested
    signal increaseRequested
    signal minimumRequested
    signal maximumRequested

    activeFocusOnTab: interactive && activationEnabled
    opacity: enabled ? 1 : 0.38
    scale: pressScaleEnabled && pressed ? pressedScale : 1

    Behavior on opacity {
        NumberAnimation {
            duration: Design.motionStateDuration
            easing.type: Design.motionStandardEasing
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: root.pressed ? Design.motionPressDuration : Design.motionStateDuration
            easing.type: Design.motionStandardEasing
        }
    }

    Rectangle {
        anchors {
            fill: parent
            margins: root.controlInset
        }
        radius: root.cornerRadius
        color: root.stateColor
        border.width: root.selected || root.externalFocus ? 1 : 0
        border.color: root.selected && root.accentSelectedOutline ? Theme.alpha(root.accentColor, 0.42) : root.outlineColor

        Behavior on color {
            ColorAnimation {
                duration: Design.motionStateDuration
                easing.type: Design.motionStandardEasing
            }
        }

        Behavior on border.color {
            ColorAnimation {
                duration: Design.motionStateDuration
                easing.type: Design.motionStandardEasing
            }
        }
    }

    Rectangle {
        anchors {
            fill: parent
            margins: root.controlInset
        }
        radius: root.cornerRadius
        color: "transparent"
        border.width: root.activeFocus ? 1 : 0
        border.color: Theme.focusRing
        opacity: root.activeFocus ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: Design.motionStateDuration
                easing.type: Design.motionStandardEasing
            }
        }
    }

    HoverHandler {
        id: hoverHandler

        enabled: root.hoverEnabled
    }

    TapHandler {
        id: primaryTap

        acceptedButtons: Qt.LeftButton
        enabled: root.enabled && root.interactive && root.activationEnabled
        onTapped: point => root.trigger(point.modifiers)
    }

    Keys.onPressed: event => {
        if (!root.enabled || !root.interactive)
            return;
        if (event.key === Qt.Key_Left || event.key === Qt.Key_Down) {
            root.decreaseRequested();
            event.accepted = true;
            return;
        }
        if (event.key === Qt.Key_Right || event.key === Qt.Key_Up) {
            root.increaseRequested();
            event.accepted = true;
            return;
        }
        if (event.key === Qt.Key_Home) {
            root.minimumRequested();
            event.accepted = true;
            return;
        }
        if (event.key === Qt.Key_End) {
            root.maximumRequested();
            event.accepted = true;
            return;
        }
        if (!root.activationEnabled)
            return;
        if (event.key !== Qt.Key_Return && event.key !== Qt.Key_Enter && event.key !== Qt.Key_Space)
            return;
        root.trigger(event.modifiers);
        event.accepted = true;
    }

    function trigger(modifiers) {
        if (!enabled || !interactive || !activationEnabled)
            return;
        if (focusOnActivate)
            forceActiveFocus();
        if (toggleable)
            selected = !selected;
        triggered(modifiers ?? Qt.NoModifier);
    }
}
