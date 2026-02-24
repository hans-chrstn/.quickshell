import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.components

ScreenCorner {
    id: root
    activeBottom: true
    activeRight: true
    aboveWindows: true
    hoverEnabled: true
    expandedWidth: 160
    expandedHeight: 140
    
    f1Rot: 90
    f1X: -20 - 10
    f1Y: 140 - 26 - 20
    
    f2Rot: 90
    f2X: 160 - 20 - 16 - 10
    f2Y: -20 + 1 - 10

    customTL: ThemeService.dynamicIslandCornerRadius
    customTR: 0
    customBL: 0
    customBR: 0

    property string confirmAction: ""

    Item {
        anchors.fill: parent
        
        Column {
            anchors.centerIn: parent
            spacing: 8
            visible: confirmAction === ""
            
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 100; height: 32; radius: 16; color: "white"
                opacity: lockMouse.containsMouse ? 0.2 : 0.1
                scale: lockMouse.containsMouse ? 1.02 : 1.0
                Behavior on opacity { NumberAnimation { duration: 200 } }
                Behavior on scale { NumberAnimation { duration: 200 } }
                Text { anchors.centerIn: parent; text: "LOCK"; color: "white"; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1 }
                MouseArea { 
                    id: lockMouse
                    anchors.fill: parent; hoverEnabled: true
                    onClicked: {
                        LockService.lockSession()
                        root.expandedState = false
                    }
                }
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 100; height: 32; radius: 16; color: "white"
                opacity: logoutMouse.containsMouse ? 0.2 : 0.1
                scale: logoutMouse.containsMouse ? 1.02 : 1.0
                Behavior on opacity { NumberAnimation { duration: 200 } }
                Behavior on scale { NumberAnimation { duration: 200 } }
                Text { anchors.centerIn: parent; text: "LOGOUT"; color: "white"; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1 }
                MouseArea { 
                    id: logoutMouse
                    anchors.fill: parent; hoverEnabled: true
                    onClicked: confirmAction = "logout"
                }
            }
            
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 100; height: 32; radius: 16; color: ThemeService.dangerColor
                opacity: pwrMouse.containsMouse ? 0.3 : 0.2
                scale: pwrMouse.containsMouse ? 1.02 : 1.0
                Behavior on opacity { NumberAnimation { duration: 200 } }
                Behavior on scale { NumberAnimation { duration: 200 } }
                Text { anchors.centerIn: parent; text: "POWER OFF"; color: ThemeService.dangerColor; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1 }
                MouseArea { 
                    id: pwrMouse
                    anchors.fill: parent; hoverEnabled: true
                    onClicked: confirmAction = "poweroff"
                }
            }
        }
        
        Column {
            anchors.centerIn: parent
            spacing: 12
            visible: confirmAction !== ""
            
            Text { 
                anchors.horizontalCenter: parent.horizontalCenter
                text: "CONFIRM ACTION?"
                color: "white"; opacity: 0.6; font.pixelSize: 9
                font.weight: Font.Bold; font.letterSpacing: 1.5 
            }
            
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 12
                
                Rectangle { 
                    width: 60; height: 32; radius: 16; color: ThemeService.dangerColor
                    Text { anchors.centerIn: parent; text: "YES"; color: "white"; font.pixelSize: 10; font.weight: Font.Bold }
                    MouseArea { 
                        anchors.fill: parent
                        onClicked: { 
                            if (confirmAction === "logout") {
                                Quickshell.execDetached(["loginctl", "terminate-user", Quickshell.env("USER")]);
                            } else {
                                Quickshell.execDetached(["systemctl", "poweroff"]);
                            }
                        } 
                    } 
                }
                
                Rectangle { 
                    width: 60; height: 32; radius: 16; color: "white"; opacity: 0.1
                    Text { anchors.centerIn: parent; text: "NO"; color: "white"; font.pixelSize: 10; font.weight: Font.Bold }
                    MouseArea { 
                        anchors.fill: parent; onClicked: confirmAction = "" 
                    } 
                }
            }
        }
    }
    
    onExpandedStateChanged: if (!expandedState) confirmAction = ""
}
