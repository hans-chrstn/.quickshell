import QtQuick
import qs.services

Item {
    id: root
    
    property var targetIsland: null
    
    width: targetIsland && targetIsland.expanded ? ThemeService.appIslandExpandedWidth : ThemeService.dynamicIslandCollapsedWidth
    height: targetIsland && targetIsland.expanded 
        ? (ThemeService.appIslandExpandedHeight + ThemeService.appIslandSearchBarHeight + 20)
        : ThemeService.thickness
        
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
        interval: ThemeService.collapseTimerDelay
        onTriggered: if (targetIsland) targetIsland.expanded = false 
    }
    
    function stopTimer() { collapseTimer.stop() }
}
