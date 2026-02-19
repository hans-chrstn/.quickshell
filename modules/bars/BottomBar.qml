import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.modules.bars
import qs.modules.island

BaseBar {
    id: root

    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    
    implicitHeight: FrameConfig.appIslandExpandedHeight
    exclusiveZone: FrameConfig.thickness
    color: "transparent"

    Rectangle {
        id: barRect
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: FrameConfig.thickness
        color: FrameConfig.color
        z: 1
    }

    AppIsland {
        id: appIsland
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        z: 2
        
        barHeight: FrameConfig.thickness
        barColor: FrameConfig.color
    }

    MouseArea {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom

        width: appIsland.expanded ? FrameConfig.appIslandExpandedWidth : FrameConfig.dynamicIslandCollapsedWidth
        height: appIsland.expanded ? FrameConfig.appIslandExpandedHeight : FrameConfig.thickness

        hoverEnabled: true

        onEntered: appIsland.expanded = true
        onExited: appIsland.expanded = false
        propagateComposedEvents: true
        onPressed: (mouse) => mouse.accepted = false
    }
}

        

    
