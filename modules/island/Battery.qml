import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.services

Item {
    id: root
    implicitWidth: 350
    implicitHeight: 80
    
    property var device: BatteryService.device

    RowLayout { 
        anchors.centerIn: parent
        width: 320
        height: 70
        spacing: 24
        
        Item {
            Layout.preferredWidth: 54
            Layout.preferredHeight: 54
            Layout.alignment: Qt.AlignVCenter

            Rectangle { 
                anchors.fill: parent
                radius: 27
                color: "transparent"
                border.width: 3
                border.color: ThemeService.backgroundContent
                opacity: 0.1
            }
            
            ClippingRectangle {
                anchors.fill: parent
                radius: 27
                color: "transparent"
                
                Rectangle { 
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: parent.height * (root.device ? root.device.percentage : 0)
                    color: (root.device && root.device.state === 1) ? ThemeService.primaryMain : ThemeService.backgroundContent
                    opacity: chargingAnim.running ? 0.4 : 0.2
                    
                    SequentialAnimation on opacity {
                        id: chargingAnim
                        running: root.device && root.device.state === 1
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.6; duration: 1000; easing.type: Easing.OutSine }
                        NumberAnimation { to: 0.3; duration: 1000; easing.type: Easing.OutSine }
                    }

                    Behavior on height { NumberAnimation { duration: 800; easing.type: Easing.OutQuart } }
                }
            }

            Text { 
                anchors.centerIn: parent
                text: root.device ? Math.round(root.device.percentage * 100) + "%" : "--"
                color: ThemeService.backgroundContent
                font.weight: Font.Black
                font.pixelSize: 11
            }
        }
        
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 0
            
            Text { 
                text: "SYSTEM POWER"
                color: ThemeService.backgroundContent
                opacity: 0.4
                font.weight: Font.Black
                font.pixelSize: 9
                font.letterSpacing: 2
            }
            Text { 
                text: root.device ? (root.device.state === 1 ? "CHARGING" : root.device.state === 2 ? "DISCHARGING" : "POWERED") : "STANDBY"
                color: ThemeService.backgroundContent
                font.weight: Font.Bold
                font.pixelSize: 15
            }
            Text { 
                text: root.device && root.device.state === 2 ? (Math.round(root.device.timeToEmpty / 60) + " MIN REMAINING") : "STABLE"
                color: ThemeService.accentColor
                opacity: 0.6
                font.pixelSize: 9
                font.weight: Font.Black; font.letterSpacing: 1
                Layout.topMargin: 2
            }
        }
    }
}
