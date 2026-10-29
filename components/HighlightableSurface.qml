import QtQuick
import qs.core

InteractionFrame {
    id: root

    property bool focused: false
    property bool contextEnabled: interactive
    property bool accentSelectedBorder: false
    property string accessibleName: ""
    property string labelText: ""
    property bool labelVisible: false
    property color labelColor: Theme.textPrimary
    property color labelBackground: Theme.overlay
    signal surfaceActivated(var modifiers)
    signal surfaceContextRequested(real x, real y, var modifiers)

    accentColor: Theme.selection
    accentSelectedOutline: accentSelectedBorder
    baseColor: Theme.fillSubtle
    externalFocus: focused
    onTriggered: modifiers => root.surfaceActivated(modifiers)

    Accessible.name: accessibleName
    Accessible.role: Accessible.Button

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

    TapHandler {
        acceptedButtons: Qt.RightButton
        enabled: root.enabled && root.contextEnabled
        onTapped: point => root.surfaceContextRequested(point.position.x, point.position.y, point.modifiers)
    }
}
