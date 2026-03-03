import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import qs.core
import qs.ui.shared

Item {
    id: root

    property string targetAction: ""
    property bool active: targetAction !== ""
    
    signal cancelRequested()

    implicitWidth: 280
    implicitHeight: 80

    opacity: root.active ? 1.0 : 0
    scale: root.active ? 1.0 : 0.9
    visible: opacity > 0.01

    Behavior on opacity { 
        NumberAnimation { 
            duration: 400
            easing.type: Easing.OutCubic
        } 
    }
    
    Behavior on scale { 
        NumberAnimation { 
            duration: 500
            easing.type: Easing.OutBack
            easing.overshoot: 1.4
        } 
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 24
        anchors.rightMargin: 24
        spacing: 24

        ColumnLayout {
            spacing: 0
            Layout.fillWidth: true
            
            StyledLabel {
                text: "CONFIRM SESSION"
                type: "caption"
                font.weight: Font.Black
                font.pixelSize: 7
                letterSpacing: 2
                opacity: 0.4
            }
            
            StyledLabel {
                text: root.targetAction.toUpperCase()
                type: "title"
                font.weight: Font.Black
                font.pixelSize: 16
                letterSpacing: 1
                customColor: (root.targetAction === "poweroff" || root.targetAction === "reboot") 
                    ? ThemeManager.dangerPrimaryColor 
                    : ThemeManager.accentColor
            }
        }

        RowLayout {
            spacing: 12
            
            BaseButton {
                id: confirmYesButton
                width: 48
                height: 48
                cornerRadius: 24
                onClicked: {
                    SoundManager.playSuccess()
                    if (root.targetAction === "logout") {
                        Quickshell.execDetached(["loginctl", "terminate-user", Quickshell.env("USER")])
                    } else if (root.targetAction === "reboot") {
                        Quickshell.execDetached(["systemctl", "reboot"])
                    } else {
                        Quickshell.execDetached(["systemctl", "poweroff"])
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 24
                    color: (root.targetAction === "poweroff" || root.targetAction === "reboot") 
                        ? ThemeManager.dangerPrimaryColor 
                        : ThemeManager.accentColor
                    
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowOpacity: 0.3
                        shadowBlur: 0.5
                        shadowVerticalOffset: 2
                    }

                    StyledLabel {
                        anchors.centerIn: parent
                        text: ThemeManager.iconCheck
                        type: "icon"
                        font.pixelSize: 20
                        customColor: ThemeManager.contentPrimaryColor
                    }
                }
            }

            BaseButton {
                id: confirmNoButton
                width: 48
                height: 48
                cornerRadius: 24
                onClicked: {
                    SoundManager.playClick()
                    root.cancelRequested()
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 24
                    color: ThemeManager.contentOnBackgroundColor
                    opacity: confirmNoButton.isHovered ? 0.12 : 0.05
                    
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 200
                        }
                    }

                    StyledLabel {
                        anchors.centerIn: parent
                        text: ThemeManager.iconClose
                        type: "icon"
                        font.pixelSize: 20
                        customColor: ThemeManager.contentOnBackgroundColor
                    }
                }
            }
        }
    }
}
