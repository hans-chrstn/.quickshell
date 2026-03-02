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
    
    expandedWidth: 340
    expandedHeight: 100
    
    firstFilletRotation: 90
    firstFilletX: -ThemeManager.dynamicIslandCornerRadius
    firstFilletY: 110 - surfaceCornerRadius - ThemeManager.dynamicIslandCornerRadius
    
    secondFilletRotation: 90
    secondFilletX: 294
    secondFilletY: 26 - surfaceCornerRadius - ThemeManager.dynamicIslandCornerRadius

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
            spacing: 24
            
            opacity: root.isConfirming ? 0 : 1
            scale: root.isConfirming ? 0.95 : 1.0
            visible: opacity > 0.01
            
            Behavior on opacity {
                NumberAnimation {
                    duration: 350
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on scale { 
                NumberAnimation { 
                    duration: 450
                    easing.type: Easing.OutBack 
                } 
            }

            UtilityButton {
                iconText: ThemeManager.iconLock
                labelText: "LOCK"
                onClicked: {
                    LockManager.lock()
                    root.isExpanded = false
                }
            }

            UtilityButton {
                iconText: ThemeManager.iconLogout
                labelText: "LOGOUT"
                onClicked: {
                    root.currentAction = "logout"
                }
            }

            UtilityButton {
                iconText: ThemeManager.iconReboot
                labelText: "REBOOT"
                onClicked: {
                    root.currentAction = "reboot"
                }
            }

            UtilityButton {
                iconText: ThemeManager.iconPower
                labelText: "POWER"
                onClicked: {
                    root.currentAction = "poweroff"
                }
            }
        }

        SessionConfirmationView {
            id: confirmView
            anchors.centerIn: parent
            targetAction: root.currentAction
            onCancelRequested: {
                root.currentAction = ""
            }
        }
    }
}
