import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config

PanelWindow {
    id: root
    property var modelData
    screen: modelData

    anchors.left: true
    anchors.top: true
    anchors.bottom: true

    implicitWidth: FrameConfig.leftBarExpanded ? 320 : 0
    color: "transparent"

    Behavior on implicitWidth {
        NumberAnimation {
            duration: FrameConfig.animDuration
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#aa222222"
        clip: true

        Item {
            anchors.fill: parent
            anchors.margins: 15
            opacity: root.implicitWidth > 200 ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 200 } }

            Column {
                anchors.centerIn: parent
                width: parent.width
                spacing: 15
                
                Text {
                    text: "Misc Stuff"
                    color: "white"
                    font.bold: true
                    font.pixelSize: 20
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                
                Repeater {
                    model: 6
                    Rectangle {
                        width: parent.width
                        height: 50
                        color: "#333"
                        radius: 8
                    }
                }
            }
        }
    }
}
