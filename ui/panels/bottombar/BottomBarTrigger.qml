import QtQuick
import qs.core

Item {
    id: root
    
    property var targetIsland: null
    
    width: targetIsland && targetIsland.isExpanded ? ThemeManager.appIslandExpandedWidth : ThemeManager.dynamicIslandCollapsedWidth
    height: targetIsland && targetIsland.isExpanded 
        ? (ThemeManager.appIslandExpandedHeight + ThemeManager.appIslandSearchBarHeight + 20)
        : ThemeManager.globalThickness

    MouseArea {
        id: triggerArea
        anchors.fill: parent
        hoverEnabled: true
        onEntered: { 
            collapseTimer.stop()
            if (targetIsland) targetIsland.isExpanded = true 
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
        onTriggered: if (targetIsland) targetIsland.isExpanded = false 
    }
    
    function stopTimer() { collapseTimer.stop() }
}
