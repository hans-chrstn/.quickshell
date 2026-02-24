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
    
    implicitHeight: ThemeService.dynamicIslandExpandedHeight
    exclusiveZone: ThemeService.thickness
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
        height: ThemeService.thickness
        color: ThemeService.color
        z: 1

        WorkspaceIndicators {
            anchors.left: parent.left
            anchors.leftMargin: ThemeService.cornerRadius + 15
            anchors.verticalCenter: parent.verticalCenter
            screenName: root.screen.name
        }
    }

    DynamicIsland {
        id: dIsland
        anchors.horizontalCenter: parent.horizontalCenter
        y: 0
        z: 2
        
        barHeight: ThemeService.thickness
        barColor: ThemeService.color
    }

    MouseArea {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: dIsland.expanded ? ThemeService.dynamicIslandExpandedWidth : ThemeService.dynamicIslandCollapsedWidth
        height: dIsland.expanded ? ThemeService.dynamicIslandExpandedHeight : ThemeService.thickness
        hoverEnabled: true
        onEntered: dIsland.expanded = true
        onExited: dIsland.expanded = false
        propagateComposedEvents: true
        onPressed: (mouse) => mouse.accepted = false
    }
}
