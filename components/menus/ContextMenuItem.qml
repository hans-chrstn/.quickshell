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
    implicitHeight: 38 + (action?.separatorBefore === true ? 9 : 0)
    opacity: actionEnabled ? 1 : 0.34

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
        height: 36
        radius: 10
        color: root.highlighted && root.actionEnabled ? (root.destructive ? Theme.tintStrong(Theme.statusDanger) : Theme.interactionSelected) : "transparent"

        Behavior on color {
            ColorAnimation {
                duration: Design.motionStateDuration
                easing.type: Design.motionStandardEasing
            }
        }

        Text {
            anchors.left: parent.left
            anchors.right: shortcutText.visible ? shortcutText.left : parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 10
            anchors.rightMargin: shortcutText.visible ? 8 : 10
            text: String(root.action?.label || "")
            color: root.destructive ? Theme.statusDanger : Theme.textPrimary
            elide: Text.ElideRight
            font.family: Design.fontText
            font.pixelSize: Design.typeLabel
            font.weight: Font.Medium
        }

        Text {
            id: shortcutText

            anchors.right: parent.right
            anchors.rightMargin: 11
            anchors.verticalCenter: parent.verticalCenter
            visible: text.length > 0
            text: String(root.action?.shortcut || "")
            color: Theme.textTertiary
            font.family: Design.fontText
            font.pixelSize: 9
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
