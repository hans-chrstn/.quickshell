import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.modules.bars
import qs.modules.island

BaseBar {
    id: root

    implicitHeight: ThemeManager.appIslandExpandedHeight + ThemeManager.appIslandSearchBarHeight + 20

    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: ThemeManager.globalThickness
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
        height: ThemeManager.globalThickness
        color: ThemeManager.backgroundColor
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
        
        barHeight: ThemeManager.globalThickness
        barColor: ThemeManager.backgroundColor
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
