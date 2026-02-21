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
    anchors.top: true
    
    exclusionMode: ExclusionMode.Ignore
    
    exclusiveZone: FrameConfig.thickness
    color: "transparent"
    
    focusable: true
    WlrLayershell.keyboardFocus: appIsland.searchVisible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    Item {
        id: islandHitbox
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        width: appIsland.expanded ? FrameConfig.appIslandExpandedWidth : FrameConfig.dynamicIslandCollapsedWidth
        height: appIsland.expanded 
            ? (FrameConfig.appIslandExpandedHeight + FrameConfig.appIslandSearchBarHeight + 20)
            : FrameConfig.thickness
            
        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
    }

    Item {
        id: maskItem
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        
        width: appIsland.searchVisible ? parent.width : islandHitbox.width
        height: appIsland.searchVisible ? parent.height : islandHitbox.height
    }

    mask: Region {
        item: maskItem
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

    MouseArea {
        anchors.fill: parent
        z: 1 
        enabled: appIsland.searchVisible || appIsland.expanded
        hoverEnabled: true
        
        onEntered: {
            if (!appIsland.searchVisible) {
                appIsland.expanded = false
            }
        }
        
        onPressed: {
            appIsland.searchVisible = false
            appIsland.expanded = false
        }
    }

    MouseArea {
        id: triggerArea
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        z: 10 
        width: FrameConfig.dynamicIslandCollapsedWidth
        height: FrameConfig.thickness
        
        hoverEnabled: true
        onEntered: appIsland.expanded = true
        propagateComposedEvents: true
        onPressed: (mouse) => mouse.accepted = false
    }
}
