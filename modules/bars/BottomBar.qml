import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.components
import qs.services
import qs.modules.bars
import qs.modules.island

BaseBar {
    id: root

    implicitHeight: FrameConfig.appIslandExpandedHeight + FrameConfig.appIslandSearchBarHeight + 20

    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: FrameConfig.thickness
    color: "transparent"
    
    focusable: true
    WlrLayershell.keyboardFocus: appIsland.searchVisible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    BottomBarTrigger {
        id: islandTrigger
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        targetIsland: appIsland
    }

    mask: Region {
        Region { item: islandTrigger }
        Region { 
            item: (osdPill.active && osdPill.opacity > 0.1) ? osdPill : null
        }
    }

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

    BottomBarOSD {
        id: osdPill
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: appIsland.height + 20
        z: 5
    }

    MouseArea {
        anchors.fill: parent
        z: 1 
        enabled: appIsland.searchVisible
        onPressed: {
            appIsland.searchVisible = false
            appIsland.expanded = false
        }
    }
}
