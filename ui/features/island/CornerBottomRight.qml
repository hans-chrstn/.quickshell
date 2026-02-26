import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import qs.core
import qs.ui.shared
import qs.ui.features.island

CornerContainer {
    id: root
    
    isAtBottom: true
    isAtRight: true
    aboveWindows: true
    isHoverEnabled: true
    
    expandedWidth: 180
    expandedHeight: 220
    
    firstFilletRotation: 90
    firstFilletX: -30
    firstFilletY: 174
    
    secondFilletRotation: 90
    secondFilletX: 134
    secondFilletY: -20 + 1 - 10

    customTopLeftRadius: ThemeManager.dynamicIslandCornerRadius
    customTopRightRadius: 0
    customBottomLeftRadius: 0
    customBottomRightRadius: 0

    property string currentAction: ""
    readonly property bool isConfirming: currentAction !== ""

    onIsExpandedChanged: {
        if (!isExpanded) {
            currentAction = ""
        }
    }

    surfaceContent: Item {
        id: mainContainer
        anchors.fill: parent
        clip: true

        ColumnLayout {
            id: headerContainer
            anchors.top: parent.top
            anchors.topMargin: 20
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 2
            opacity: root.isConfirming ? 0 : 1
            Behavior on opacity { NumberAnimation { duration: 300 } }

            Text {
                id: sessionLabel
                text: "SESSION"
                color: ThemeManager.contentOnBackgroundColor
                font.pixelSize: 8
                font.weight: Font.Black
                font.letterSpacing: 2
                opacity: 0.4
                Layout.alignment: Qt.AlignHCenter
            }
            Rectangle {
                id: headerLine
                Layout.preferredWidth: 20
                Layout.preferredHeight: 2
                radius: 1
                color: ThemeManager.accentColor
                opacity: 0.3
                Layout.alignment: Qt.AlignHCenter
            }
        }

        ColumnLayout {
            id: actionsListContainer
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 10
            spacing: 12
            
            opacity: root.isConfirming ? 0 : 1
            scale: root.isConfirming ? 0.9 : 1.0
            visible: opacity > 0.01
            
            Behavior on opacity { NumberAnimation { duration: 300 } }
            Behavior on scale { 
                NumberAnimation { 
                    duration: 400
                    easing.type: Easing.OutBack 
                } 
            }

            SessionActionTile {
                actionIcon: "󰌾"
                actionLabel: "LOCK"
                onActionTriggered: {
                    LockManager.lock()
                    root.isExpanded = false
                }
            }

            SessionActionTile {
                actionIcon: "󰍃"
                actionLabel: "LOGOUT"
                onActionTriggered: root.currentAction = "logout"
            }

            SessionActionTile {
                actionIcon: "󰐥"
                actionLabel: "POWER"
                actionHighlightColor: ThemeManager.dangerPrimaryColor
                onActionTriggered: root.currentAction = "poweroff"
            }
        }

        ColumnLayout {
            id: confirmationContainer
            anchors.centerIn: parent
            spacing: 20
            
            opacity: root.isConfirming ? 1 : 0
            scale: root.isConfirming ? 1.0 : 1.1
            visible: opacity > 0.01
            
            Behavior on opacity { NumberAnimation { duration: 300 } }
            Behavior on scale { 
                NumberAnimation { 
                    duration: 400
                    easing.type: Easing.OutExpo 
                } 
            }

            ColumnLayout {
                spacing: 4
                Layout.alignment: Qt.AlignHCenter
                
                Text {
                    id: confirmationQuestionLabel
                    text: "ARE YOU SURE?"
                    color: ThemeManager.contentOnBackgroundColor
                    font.pixelSize: 10
                    font.weight: Font.Black
                    font.letterSpacing: 1
                    Layout.alignment: Qt.AlignHCenter
                }
                Text {
                    id: actionTypeLabel
                    text: root.currentAction.toUpperCase()
                    color: root.currentAction === "poweroff" ? ThemeManager.dangerPrimaryColor : ThemeManager.accentColor
                    font.pixelSize: 12
                    font.weight: Font.Bold
                    font.letterSpacing: 2
                    Layout.alignment: Qt.AlignHCenter
                }
            }

            RowLayout {
                spacing: 16
                Layout.alignment: Qt.AlignHCenter

                BaseButton {
                    id: confirmYesButton
                    Layout.preferredWidth: 60
                    Layout.preferredHeight: 40
                    onClicked: {
                        SoundManager.playSuccess()
                        if (root.currentAction === "logout") {
                            Quickshell.execDetached(["loginctl", "terminate-user", Quickshell.env("USER")]);
                        } else {
                            Quickshell.execDetached(["systemctl", "poweroff"]);
                        }
                    }
                    
                    Rectangle {
                        anchors.fill: parent
                        radius: 20
                        color: root.currentAction === "poweroff" ? ThemeManager.dangerPrimaryColor : ThemeManager.accentColor
                        
                        Text {
                            anchors.centerIn: parent
                            text: "YES"
                            color: ThemeManager.contentPrimaryColor
                            font.pixelSize: 11
                            font.weight: Font.Black
                        }
                    }
                }

                BaseButton {
                    id: confirmNoButton
                    Layout.preferredWidth: 60
                    Layout.preferredHeight: 40
                    onClicked: {
                        SoundManager.playClick()
                        root.currentAction = ""
                    }
                    
                    Rectangle {
                        anchors.fill: parent
                        radius: 20
                        color: ThemeManager.contentOnBackgroundColor
                        opacity: confirmNoButton.isHovered ? 0.15 : 0.1
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                        
                        Text {
                            anchors.centerIn: parent
                            text: "NO"
                            color: ThemeManager.contentOnBackgroundColor
                            font.pixelSize: 11
                            font.weight: Font.Bold
                        }
                    }
                }
            }
        }
    }
}
