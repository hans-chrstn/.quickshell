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
import "./bottomright"

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
            Behavior on opacity {
                NumberAnimation {
                    duration: 300
                }
            }

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
                onActionTriggered: {
                    root.currentAction = "logout"
                }
            }

            SessionActionTile {
                actionIcon: "󰐥"
                actionLabel: "POWER"
                actionHighlightColor: ThemeManager.dangerPrimaryColor
                onActionTriggered: {
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
