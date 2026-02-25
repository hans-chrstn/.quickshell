import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Services.Notifications
import qs.modules.island
import qs.services
import qs.modules.bars

BaseBar {
    id: root
    
    anchors.top: true
    anchors.left: true
    anchors.right: true
    
    implicitHeight: ThemeManager.dynamicIslandExpandedHeight
    exclusiveZone: ThemeManager.globalThickness
    color: "transparent"
    focusable: dIsland.expanded

    mask: Region {
        Region { item: barRect }
        Region { item: dIsland }
    }

    Rectangle {
        id: barRect
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: ThemeManager.globalThickness
        color: ThemeManager.backgroundColor
        z: 1

        WorkspaceIndicators {
            anchors.left: parent.left
            anchors.leftMargin: ThemeManager.globalCornerRadius + 15
            anchors.verticalCenter: parent.verticalCenter
            screenName: root.screen.name
        }
    }

    DynamicIsland {
        id: dIsland
        anchors.horizontalCenter: parent.horizontalCenter
        y: 0
        z: 2
        
        barHeight: ThemeManager.globalThickness
        barColor: ThemeManager.backgroundColor
    }

    MouseArea {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: dIsland.expanded ? ThemeManager.dynamicIslandExpandedWidth : ThemeManager.dynamicIslandCollapsedWidth
        height: dIsland.expanded ? ThemeManager.dynamicIslandExpandedHeight : ThemeManager.globalThickness
        hoverEnabled: true
        onEntered: dIsland.expanded = true
        onExited: dIsland.expanded = false
        propagateComposedEvents: true
        onPressed: (mouse) => mouse.accepted = false
    }
}
