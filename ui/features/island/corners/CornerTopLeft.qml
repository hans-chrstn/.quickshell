pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.core
import qs.ui.shared
import qs.ui.shared.shapes

CornerContainer {
    id: cornerRoot
    isAtTop: true
    isAtLeft: true
    aboveWindows: true
    
    firstFilletRotation: 0
    firstFilletX: expandedWidth - 1
    firstFilletY: 16
    
    secondFilletRotation: 270
    secondFilletX: 16
    secondFilletY: expandedHeight - 1
    
    customTopLeftRadius: 0
    customTopRightRadius: 0
    customBottomLeftRadius: 0
    customBottomRightRadius: ThemeManager.dynamicIslandCornerRadius

    Item {
        id: triggerArea
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: -8
        anchors.verticalCenterOffset: -8
        width: 32
        height: 32
        z: 100

        HoverHandler {
            id: hh
            onHoveredChanged: {
                ViewManager.dashboardTriggerHovered = hovered
            }
        }

        Rectangle {
            id: glyph
            anchors.centerIn: parent
            width: hh.hovered ? 10 : 6
            height: width
            radius: width / 2
            color: ThemeManager.accentColor
            opacity: ViewManager.leftDashboardOpen ? 1.0 : 0.3

            Behavior on width { 
                NumberAnimation { 
                    duration: ThemeManager.animationDuration
                    easing.type: ThemeManager.animationEasing
                } 
            }
            
            Behavior on opacity { 
                NumberAnimation { 
                    duration: ThemeManager.animationDuration
                    easing.type: ThemeManager.animationEasing
                } 
            }

            Rectangle {
                anchors.centerIn: parent
                width: parent.width + 4
                height: width
                radius: width / 2
                color: "transparent"
                border.color: ThemeManager.accentColor
                border.width: 1
                opacity: hh.hovered ? 0.3 : 0
                
                Behavior on opacity { 
                    NumberAnimation { 
                        duration: ThemeManager.animationDuration
                        easing.type: ThemeManager.animationEasing
                    } 
                }
            }
        }
    }
}
