import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.modules.bars
import qs.modules.island

BaseBar {
    id: root

    implicitHeight: ThemeService.appIslandExpandedHeight + ThemeService.appIslandSearchBarHeight + 20

    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: ThemeService.thickness
    color: "transparent"
    
    focusable: true
    WlrLayershell.keyboardFocus: appIsland.searchVisible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    mask: Region {
        Region { item: barRect }
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
        height: ThemeService.thickness
        color: ThemeService.color
        z: 1
    }

    BottomBarTrigger {
        id: islandTrigger
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        targetIsland: appIsland
    }

    AppIsland {
        id: appIsland
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        z: 2
        
        barHeight: ThemeService.thickness
        barColor: ThemeService.color
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
