import QtQuick
import qs.core

Item {
    id: root

    required property var action
    property bool highlighted: false
    signal hovered
    signal triggered

    readonly property bool actionEnabled: action?.enabled !== false
    readonly property bool destructive: action?.destructive === true
    implicitHeight: 34 + (action?.separatorBefore === true ? 7 : 0)

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 1
        visible: root.action?.separatorBefore === true
        color: Theme.separator
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 32
        radius: 9
        color: root.highlighted && root.actionEnabled ? (root.destructive ? Theme.tint(Theme.danger) : Theme.fillElevated) : "transparent"
        border.width: root.highlighted && root.actionEnabled ? 1 : 0
        border.color: root.destructive ? Theme.tintStrong(Theme.danger) : Theme.glassHighlight

        Behavior on color {
            ColorAnimation {
                duration: 90
            }
        }

        Text {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            text: String(root.action?.label || "")
            color: !root.actionEnabled ? Theme.textSecondary : root.destructive ? Theme.danger : Theme.textPrimary
            opacity: root.actionEnabled ? 1 : 0.48
            elide: Text.ElideRight
            font.family: Design.fontText
            font.pixelSize: 11
            font.weight: Font.Medium
        }
    }

    HoverHandler {
        enabled: root.actionEnabled
        onHoveredChanged: if (hovered)
            root.hovered()
    }
    TapHandler {
        enabled: root.actionEnabled
        acceptedButtons: Qt.LeftButton
        onTapped: root.triggered()
    }
}
