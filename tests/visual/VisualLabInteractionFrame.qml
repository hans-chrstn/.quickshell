import QtQuick

FocusScope {
    id: root

    property string semanticRole: "neutral"
    property bool selected: false
    property bool selectionFillEnabled: true
    property bool toggleable: true
    property bool activationEnabled: true
    property bool externallyPressed: false
    property real controlRadius: 13
    property real controlInset: 3
    signal activated
    signal decreaseRequested
    signal increaseRequested
    signal minimumRequested
    signal maximumRequested

    activeFocusOnTab: enabled
    opacity: enabled ? 1 : 0.38
    scale: pressHandler.pressed ? 0.985 : 1

    readonly property bool hovered: hoverHandler.hovered
    readonly property bool pressed: activationEnabled ? pressHandler.pressed : externallyPressed
    readonly property color semanticColor: semanticRole === "warning" ? "#ffffa21a" : semanticRole === "destructive" ? "#ffff453a" : "#ffffa21a"
    readonly property color stateColor: pressed ? "#1cffffff" : selected && selectionFillEnabled ? "#14ffffff" : hovered ? "#0dffffff" : "transparent"

    Behavior on opacity {
        NumberAnimation {
            duration: 140
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: root.pressed ? 80 : 150
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        anchors {
            fill: parent
            margins: root.controlInset
        }
        radius: root.controlRadius
        color: root.stateColor

        Behavior on color {
            ColorAnimation {
                duration: 120
            }
        }
    }

    Rectangle {
        anchors {
            fill: parent
            margins: root.controlInset
        }
        radius: root.controlRadius
        color: "transparent"
        border.width: root.activeFocus ? 1 : 0
        border.color: "#78ffffff"
        opacity: root.activeFocus ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 140
            }
        }
    }

    HoverHandler {
        id: hoverHandler
    }

    TapHandler {
        id: pressHandler

        enabled: root.activationEnabled
        onTapped: root.activate()
    }

    Keys.onPressed: event => {
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
        root.activate();
        event.accepted = true;
    }

    function activate() {
        if (!activationEnabled)
            return;
        forceActiveFocus();
        if (toggleable)
            selected = !selected;
        activated();
    }
}
