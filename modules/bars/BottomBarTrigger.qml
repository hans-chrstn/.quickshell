import QtQuick
import qs.config

Item {
    id: root
    
    property var targetIsland: null
    
    width: targetIsland && targetIsland.expanded ? FrameConfig.appIslandExpandedWidth : FrameConfig.dynamicIslandCollapsedWidth
    height: targetIsland && targetIsland.expanded 
        ? (FrameConfig.appIslandExpandedHeight + FrameConfig.appIslandSearchBarHeight + 20)
        : FrameConfig.thickness
        
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
        interval: FrameConfig.collapseTimerDelay
        onTriggered: if (targetIsland) targetIsland.expanded = false 
    }
    
    function stopTimer() { collapseTimer.stop() }
}
