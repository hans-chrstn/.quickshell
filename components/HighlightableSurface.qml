import QtQuick
import qs.core

Item {
    id: root

    property bool selected: false
    property bool focused: false
    property bool interactive: true
    property bool contextEnabled: interactive
    property bool hoverEnabled: true
    property color accentColor: Design.blue
    property color baseColor: Qt.rgba(1, 1, 1, 0.035)
    property real cornerRadius: 10
    property string accessibleName: ""
    property string labelText: ""
    property bool labelVisible: false
    property color labelColor: Design.text
    property color labelBackground: Design.islandExpanded
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
        color: root.selected ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.30) : root.baseColor
        border.width: root.selected ? 1.5 : root.highlighted ? 1 : 0
        border.color: root.selected ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.62) : Qt.rgba(1, 1, 1, 0.12)

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
        border.color: Qt.rgba(1, 1, 1, 0.12)
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
