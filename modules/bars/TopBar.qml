import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import Quickshell.Services.UPower
import Quickshell.Services.Notifications
import qs.modules.island
import qs.config
import qs.modules.bars
import qs.services

BaseBar {
    id: root
    
    anchors.top: true
    anchors.left: true
    anchors.right: true
    
    implicitHeight: FrameConfig.dynamicIslandExpandedHeight
    exclusiveZone: FrameConfig.thickness
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
        height: FrameConfig.thickness
        color: FrameConfig.color
        z: 1

        WorkspaceIndicators {
            anchors.left: parent.left
            anchors.leftMargin: FrameConfig.cornerRadius + 15
            anchors.verticalCenter: parent.verticalCenter
            screenName: root.screen.name
        }
    }

    DynamicIsland {
        id: dIsland
        anchors.horizontalCenter: parent.horizontalCenter
        y: 0
        z: 2
        
        barHeight: FrameConfig.thickness
        barColor: FrameConfig.color
    }

    MouseArea {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: dIsland.expanded ? FrameConfig.dynamicIslandExpandedWidth : FrameConfig.dynamicIslandCollapsedWidth
        height: dIsland.expanded ? FrameConfig.dynamicIslandExpandedHeight : FrameConfig.thickness
        hoverEnabled: true
        onEntered: dIsland.expanded = true
        onExited: dIsland.expanded = false
        propagateComposedEvents: true
        onPressed: (mouse) => mouse.accepted = false
    }
}
