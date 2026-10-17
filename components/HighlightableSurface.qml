import QtQuick
import qs.core

Item {
    id: root

    property bool selected: false
    property bool focused: false
    property bool interactive: true
    property bool contextEnabled: interactive
    property bool hoverEnabled: true
    property color accentColor: Theme.accent
    property bool accentSelectedBorder: false
    property color baseColor: Theme.fillSubtle
    property real cornerRadius: 10
    property string accessibleName: ""
    property string labelText: ""
    property bool labelVisible: false
    property color labelColor: Theme.textPrimary
    property color labelBackground: Theme.overlay
    readonly property bool hovered: hover.hovered
    readonly property bool highlighted: selected || focused || hovered
    signal surfaceActivated(var modifiers)
    signal surfaceContextRequested(real x, real y, var modifiers)

    activeFocusOnTab: interactive
    Accessible.name: accessibleName
    Accessible.role: Accessible.Button

    Keys.onPressed: event => {
        if (!root.interactive)
            return;
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            root.surfaceActivated(event.modifiers);
            event.accepted = true;
        }
    }

    Rectangle {
        id: surface
        anchors.fill: parent
        radius: root.cornerRadius
        color: primaryTap.pressed ? Theme.controlPressed : root.selected ? Theme.fillSelected : root.hovered || root.focused ? Theme.controlHover : root.baseColor
        border.width: root.highlighted ? 1 : 0
        border.color: root.selected && root.accentSelectedBorder ? Theme.alpha(root.accentColor, 0.42) : Theme.separatorStrong

        Behavior on color {
            ColorAnimation {
                duration: 110
            }
        }
        Behavior on border.color {
            ColorAnimation {
                duration: 110
            }
        }
    }

    Rectangle {
        visible: root.labelVisible && root.labelText.length > 0
        x: 6
        y: -2
        width: label.implicitWidth + 10
        height: label.implicitHeight + 5
        radius: height / 2
        color: root.labelBackground
        border.width: 1
        border.color: Theme.separatorStrong
        z: 20

        Text {
            id: label
            anchors.centerIn: parent
            text: root.labelText
            color: root.labelColor
            font.family: Design.fontText
            font.pixelSize: 8
            elide: Text.ElideRight
            maximumLineCount: 1
        }
    }

    HoverHandler {
        id: hover
        enabled: root.hoverEnabled
    }

    TapHandler {
        id: primaryTap
        acceptedButtons: Qt.LeftButton
        enabled: root.interactive
        onTapped: point => {
            root.forceActiveFocus();
            root.surfaceActivated(point.modifiers);
        }
    }

    TapHandler {
        acceptedButtons: Qt.RightButton
        enabled: root.contextEnabled
        onTapped: point => root.surfaceContextRequested(point.position.x, point.position.y, point.modifiers)
    }
}
