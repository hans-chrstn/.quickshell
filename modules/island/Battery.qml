import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.services

Item {
    id: root
    
    property var device: BatteryService.device

    RowLayout { 
        anchors.fill: parent
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        spacing: 24
        
        Item {
            Layout.preferredWidth: 64
            Layout.preferredHeight: 64
            Layout.alignment: Qt.AlignVCenter

            Rectangle { 
                anchors.fill: parent
                radius: 32
                color: "transparent"
                border.width: 4
                border.color: "white"
                opacity: 0.1
            }
            
            ClippingRectangle {
                anchors.fill: parent
                radius: 32
                color: "transparent"
                
                Rectangle { 
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: parent.height * (root.device ? root.device.percentage : 0)
                    color: (root.device && root.device.state === 1) ? "#4caf50" : "white"
                    opacity: chargingAnim.running ? 0.4 : 0.2
                    
                    SequentialAnimation on opacity {
                        id: chargingAnim
                        running: root.device && root.device.state === 1
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.6; duration: 1000; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 0.3; duration: 1000; easing.type: Easing.InOutSine }
                    }

                    Behavior on height { NumberAnimation { duration: 800; easing.type: Easing.OutQuart } }
                }
            }

            Text { 
                anchors.centerIn: parent
                text: root.device ? Math.round(root.device.percentage * 100) + "%" : "--"
                color: "white"
                font.weight: Font.Bold
                font.pixelSize: 14
            }
        }
        
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 0
            
            Text { 
                text: "SYSTEM POWER"
                color: "white"
                opacity: 0.5
                font.weight: Font.Bold
                font.pixelSize: 9
                font.letterSpacing: 1
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignLeft
            }
            Text { 
                text: root.device ? (root.device.state === 1 ? "CHARGING" : root.device.state === 2 ? "DISCHARGING" : "UNKNOWN") : "UNKNOWN"
                color: "white"
                font.weight: Font.DemiBold
                font.pixelSize: 14
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignLeft
                Layout.topMargin: 2
            }
            Text { 
                text: root.device ? (Math.round(root.device.timeToEmpty / 60) + " MIN REMAINING") : ""
                visible: root.device && root.device.state === 2
                color: "white"
                opacity: 0.4
                font.pixelSize: 9
                font.weight: Font.Medium
                font.letterSpacing: 0.5
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignLeft
                Layout.topMargin: 4
            }
        }
    }
}
