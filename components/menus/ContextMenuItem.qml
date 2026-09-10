import QtQuick
import qs.core

Item {
    id: root

    required property var action
    property bool highlighted: false
    signal hovered()
    signal triggered()

    readonly property bool actionEnabled: action?.enabled !== false
    readonly property bool destructive: action?.destructive === true
    implicitHeight: 34 + (action?.separatorBefore === true ? 7 : 0)

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 1
        visible: root.action?.separatorBefore === true
        color: Design.separator
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 32
        radius: 9
        color: root.highlighted && root.actionEnabled
            ? (root.destructive
                ? Qt.rgba(Design.red.r, Design.red.g, Design.red.b, 0.13)
                : Qt.rgba(1, 1, 1, 0.09))
            : "transparent"
        border.width: root.highlighted && root.actionEnabled ? 1 : 0
        border.color: root.destructive
            ? Qt.rgba(Design.red.r, Design.red.g, Design.red.b, 0.26)
            : Design.glassHighlight

        Behavior on color { ColorAnimation { duration: 90 } }

        Text {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            text: String(root.action?.label || "")
            color: !root.actionEnabled ? Design.textMuted
                : root.destructive ? Design.red : Design.text
            opacity: root.actionEnabled ? 1 : 0.48
            elide: Text.ElideRight
            font.family: Design.fontText
            font.pixelSize: 11
            font.weight: Font.Medium
        }
    }

    HoverHandler {
        enabled: root.actionEnabled
        onHoveredChanged: if (hovered) root.hovered()
    }
    TapHandler {
        enabled: root.actionEnabled
        acceptedButtons: Qt.LeftButton
        onTapped: root.triggered()
    }
}
