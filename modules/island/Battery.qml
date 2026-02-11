import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower

Item {
    id: root
    
    property var device: UPower.displayDevice

    RowLayout { 
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 20
        
        Rectangle { 
            Layout.preferredWidth: 60
            Layout.preferredHeight: 60
            radius: 30
            color: "transparent"
            border.width: 4
            border.color: "#333"
            clip: true
            Layout.alignment: Qt.AlignVCenter
            
            Rectangle { 
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: parent.height * (root.device ? root.device.percentage / 100 : 0)
                color: (root.device && root.device.state === UPowerDeviceState.Charging) ? "#4caf50" : "white"
                opacity: 0.8
                Behavior on height { NumberAnimation { duration: 500 } }
            }
            
            Text { 
                anchors.centerIn: parent
                text: root.device ? Math.round(root.device.percentage * 100) + "%" : "--"
                color: "white"
                font.bold: true
            }
        }
        
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            
            Text { 
                text: "Battery"
                color: "#aaa"
                font.pixelSize: 12
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignLeft
            }
            Text { 
                text: root.device ? UPowerDeviceState.toString(root.device.state) : "Unknown"
                color: "white"
                font.bold: true
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignLeft
            }
            Text { 
                text: root.device ? (Math.round(root.device.timeToEmpty / 60) + " min left") : ""
                visible: root.device && root.device.state === UPowerDeviceState.Discharging
                color: "#888"
                font.pixelSize: 10
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignLeft
            }
        }
    }
}
