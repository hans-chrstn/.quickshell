import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import qs.config

Rectangle {
    id: root
    
    property string icon: ""
    property real value: 0
    property color barColor: FrameConfig.accentColor
    property bool active: false
    
    signal moved(real val)
    signal iconClicked()

    radius: 22
    color: "#080809"
    
    Rectangle {
        anchors.fill: parent; radius: parent.radius; color: "transparent"
        border.color: Qt.rgba(1, 1, 1, 0.2); border.width: 1
        
        Rectangle {
            anchors.fill: parent; anchors.margins: 1; radius: parent.radius - 1; color: "transparent"
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.1) }
                GradientStop { position: 0.4; color: "transparent" }
            }
        }
    }

    Rectangle {
        width: parent.width * 1.5; height: parent.height
        rotation: -45; x: -parent.width * 0.2; y: -parent.height * 0.5
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.05) }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }
    
    opacity: active ? 1.0 : 0.0
    scale: active ? 1.0 : 0.95
    
    Behavior on opacity { NumberAnimation { duration: 300 } }
    Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }

    RowLayout {
        anchors.fill: parent; anchors.leftMargin: 20; anchors.rightMargin: 20
        spacing: 14; z: 1

        Text {
            text: root.icon
            color: "white"; font.pixelSize: 18
            opacity: hhIcon.hovered ? 1.0 : 0.7
            Behavior on opacity { NumberAnimation { duration: 200 } }
            TapHandler { onTapped: root.iconClicked() }
            HoverHandler { id: hhIcon; cursorShape: Qt.PointingHandCursor }
        }

        Item {
            Layout.fillWidth: true; Layout.preferredHeight: 16 
            Rectangle {
                anchors.centerIn: parent
                width: parent.width; height: 6; radius: 3; color: "black"; opacity: 0.6
                border.color: Qt.rgba(1, 1, 1, 0.05); border.width: 1
            }
            Rectangle {
                id: fillBar
                anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                height: 6; radius: 3
                width: parent.width * Math.max(0, Math.min(1, root.value))
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: root.barColor }
                    GradientStop { position: 1.0; color: Qt.lighter(root.barColor, 1.3) }
                }
                Rectangle {
                    anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                    anchors.rightMargin: -2; width: 6; height: 10; radius: 3
                    color: "white"; opacity: 0.6; visible: root.value > 0.05
                    layer.enabled: true; layer.effect: MultiEffect { blurEnabled: true; blur: 0.3 }
                }
                Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
            }
            MouseArea {
                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                preventStealing: true
                function handleMove(mouse) { root.moved(Math.max(0, Math.min(1, mouse.x / width))) }
                onPressed: (mouse) => handleMove(mouse)
                onPositionChanged: (mouse) => { if (pressed) handleMove(mouse) }
            }
        }

        Text {
            text: Math.round(root.value * 100)
            color: "white"; font.pixelSize: 12; font.weight: Font.Black; opacity: 0.3
            Layout.preferredWidth: 25; horizontalAlignment: Text.AlignRight
        }
    }
}
