import QtQuick
import qs.core

Item {
    id: root

    required property Flickable target
    property color edgeColor: Design.islandExpanded
    property real fadeHeight: 14

    anchors.fill: parent
    z: 10

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: root.fadeHeight
        opacity: root.target.atYBeginning ? 0 : 1

        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0; color: root.edgeColor }
            GradientStop { position: 1; color: "transparent" }
        }

        Behavior on opacity {
            NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: root.fadeHeight
        opacity: root.target.atYEnd ? 0 : 1

        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0; color: "transparent" }
            GradientStop { position: 1; color: root.edgeColor }
        }

        Behavior on opacity {
            NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
        }
    }
}
