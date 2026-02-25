import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.core

Item {
    id: root
    
    implicitWidth: 350
    implicitHeight: 80
    
    readonly property var batteryDevice: BatteryManager.mainDevice

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
                border.color: ThemeManager.contentOnBackgroundColor
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
                    height: parent.height * (root.batteryDevice ? root.batteryDevice.percentage : 0)
                    color: (root.batteryDevice && root.batteryDevice.state === 1) ? ThemeManager.primaryColor : ThemeManager.contentOnBackgroundColor
                    opacity: chargingPulseAnimation.running ? 0.4 : 0.2
                    
                    SequentialAnimation on opacity {
                        id: chargingPulseAnimation
                        running: root.batteryDevice && root.batteryDevice.state === 1
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.6; duration: 1000; easing.type: Easing.OutSine }
                        NumberAnimation { to: 0.3; duration: 1000; easing.type: Easing.OutSine }
                    }

                    Behavior on height { 
                        NumberAnimation { 
                            duration: 800
                            easing.type: Easing.OutQuart 
                        } 
                    }
                }
            }

            Text { 
                anchors.centerIn: parent
                text: root.batteryDevice ? Math.round(root.batteryDevice.percentage * 100) + "%" : "--"
                color: ThemeManager.contentOnBackgroundColor
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
                color: ThemeManager.contentOnBackgroundColor
                opacity: 0.4
                font.weight: Font.Black
                font.pixelSize: 9
                font.letterSpacing: 2
            }
            Text { 
                text: {
                    if (!root.batteryDevice) return "STANDBY"
                    switch (root.batteryDevice.state) {
                        case 1: return "CHARGING"
                        case 2: return "DISCHARGING"
                        default: return "POWERED"
                    }
                }
                color: ThemeManager.contentOnBackgroundColor
                font.weight: Font.Bold
                font.pixelSize: 15
            }
            Text { 
                text: root.batteryDevice && root.batteryDevice.state === 2 
                    ? (Math.round(root.batteryDevice.timeToEmpty / 60) + " MIN REMAINING") 
                    : "STABLE"
                color: ThemeManager.accentColor
                opacity: 0.6
                font.pixelSize: 9
                font.weight: Font.Black
                font.letterSpacing: 1
                Layout.topMargin: 2
            }
        }
    }
}
