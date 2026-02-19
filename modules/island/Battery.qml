import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.UPower

Item {
    id: root
    
    property var device: UPower.displayDevice

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
                    height: parent.height * (root.device ? root.device.percentage / 100 : 0)
                    color: (root.device && root.device.state === UPowerDeviceState.Charging) ? "#4caf50" : "white"
                    opacity: 0.2
                    Behavior on height { NumberAnimation { duration: 800; easing.type: Easing.OutQuart } }
                }
            }

            Text { 
                anchors.centerIn: parent
                text: root.device ? Math.round(root.device.percentage) + "%" : "--"
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
                text: root.device ? UPowerDeviceState.toString(root.device.state).toUpperCase() : "UNKNOWN"
                color: "white"
                font.weight: Font.DemiBold
                font.pixelSize: 14
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignLeft
                Layout.topMargin: 2
            }
            Text { 
                text: root.device ? (Math.round(root.device.timeToEmpty / 60) + " MIN REMAINING") : ""
                visible: root.device && root.device.state === UPowerDeviceState.Discharging
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
