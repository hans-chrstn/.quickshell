import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import qs.core
import qs.ui.shared
import qs.ui.features.island
import qs.ui.shared.shapes
import qs.ui.features.island.system
import qs.ui.features.island.corners.shared
import "./bottomright"

CornerContainer {
    id: root
    
    isAtBottom: true
    isAtRight: true
    aboveWindows: true
    isHoverEnabled: true
    
    expandedWidth: 300
    expandedHeight: 100
    
    firstFilletRotation: 90
    firstFilletX: -20 - 10
    firstFilletY: 100 - 16 - 10 - 1
    
    secondFilletRotation: 90
    secondFilletX: 300 - 20 - 16 - 10
    secondFilletY: -20 - 10

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

        Row {
            id: actionsListContainer
            anchors.centerIn: parent
            spacing: 20
            
            opacity: root.isConfirming ? 0 : 1
            scale: root.isConfirming ? 0.9 : 1.0
            visible: opacity > 0.01
            
            Behavior on opacity {
                NumberAnimation {
                    duration: 300
                }
            }
            Behavior on scale { 
                NumberAnimation { 
                    duration: 400
                    easing.type: Easing.OutBack 
                } 
            }

            UtilityButton {
                iconText: "󰌾"
                labelText: "LOCK"
                onClicked: {
                    LockManager.lock()
                    root.isExpanded = false
                }
            }

            UtilityButton {
                iconText: "󰍃"
                labelText: "LOGOUT"
                onClicked: {
                    root.currentAction = "logout"
                }
            }

            UtilityButton {
                iconText: "󰑓"
                labelText: "REBOOT"
                onClicked: {
                    root.currentAction = "reboot"
                }
            }

            UtilityButton {
                iconText: "󰐥"
                labelText: "POWER"
                onClicked: {
                    root.currentAction = "poweroff"
                }
            }
        }

        SessionConfirmationView {
            anchors.centerIn: parent
            currentAction: root.currentAction
            onCurrentActionChanged: {
                root.currentAction = currentAction
            }
        }
    }
}
