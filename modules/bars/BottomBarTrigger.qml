import QtQuick
import qs.services

Item {
    id: root
    
    property var targetIsland: null
    
    width: targetIsland && targetIsland.expanded ? ThemeManager.appIslandExpandedWidth : ThemeManager.dynamicIslandCollapsedWidth
    height: targetIsland && targetIsland.expanded 
        ? (ThemeManager.appIslandExpandedHeight + ThemeManager.appIslandSearchBarHeight + 20)
        : ThemeManager.globalThickness
        
    Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }

    MouseArea {
        id: triggerArea
        anchors.fill: parent
        hoverEnabled: true
        onEntered: { 
            collapseTimer.stop()
            if (targetIsland) targetIsland.expanded = true 
        }
        onExited: { 
            if (targetIsland && !targetIsland.searchVisible) collapseTimer.restart() 
        }
        propagateComposedEvents: true
        onPressed: (mouse) => mouse.accepted = false
    }

    Timer { 
        id: collapseTimer
        interval: ThemeManager.islandCollapseDelay
        onTriggered: if (targetIsland) targetIsland.expanded = false 
    }
    
    function stopTimer() { collapseTimer.stop() }
}
