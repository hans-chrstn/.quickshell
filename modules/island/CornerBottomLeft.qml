import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import qs.services
import qs.components
import qs.modules.bars

ScreenCorner {
    id: cornerRoot
    activeBottom: true
    activeLeft: true
    aboveWindows: true
    
    hoverEnabled: false 
    expandedWidth: 240
    expandedHeight: 80
    
    f1Rot: 180
    f1X: islandItem.width - 1
    f1Y: islandItem.height - ThemeService.thickness - ThemeService.dynamicIslandCornerRadius + 10
    
    f2Rot: 180
    f2X: 16
    f2Y: -30
    
    customTL: 0
    customTR: ThemeService.dynamicIslandCornerRadius
    customBL: 0
    customBR: 0

    property int activeAppIndex: -1
    
    // readonly property var activeAppItem: {
    //     if (!SystemTrayService.model || activeAppIndex === -1) return null
    //     let vals = SystemTrayService.model.values
    //     if (vals && activeAppIndex < vals.length) return vals[activeAppIndex]
    //     return null
    // }

    // Connections {
    //     target: SystemTrayService
    //     function onHoveredIndexChanged() {
    //         if (SystemTrayService.hoveredIndex !== -1) {
    //             cornerRoot.activeAppIndex = SystemTrayService.hoveredIndex
    //             cornerRoot.expandedState = true
    //         } else {
    //             cornerRoot.expandedState = false
    //         }
    //     }
    // }

    Item {
        anchors.fill: parent
        anchors.leftMargin: 15
        anchors.rightMargin: 15

        Item {
            anchors.fill: parent
            opacity: cornerRoot.expandedState ? 1.0 : 0.0
            scale: cornerRoot.expandedState ? 1.0 : 0.95
            visible: opacity > 0.01
            
            Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }

            RowLayout {
                anchors.fill: parent
                spacing: 12
                visible: cornerRoot.activeAppItem !== null

                Rectangle {
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    radius: 10
                    color: ThemeService.surfaceVariant
                    
                    IconImage {
                        anchors.fill: parent
                        anchors.margins: 8
                        source: cornerRoot.activeAppItem ? cornerRoot.activeAppItem.icon : ""
                    }
                }

                ColumnLayout {
                    spacing: 0
                    Text {
                        text: cornerRoot.activeAppItem ? (cornerRoot.activeAppItem.title || "SYSTEM TRAY").toUpperCase() : ""
                        color: ThemeService.backgroundContent
                        font.pixelSize: 11; font.weight: Font.Black; font.letterSpacing: 1
                    }
                    Text {
                        text: "BACKGROUND SERVICE"
                        color: ThemeService.accentColor
                        opacity: 0.6; font.pixelSize: 8; font.weight: Font.Bold; font.letterSpacing: 0.5
                    }
                }
            }
        }
    }
}
