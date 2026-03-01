import QtQuick
import Quickshell
import qs.core

QtObject {
    id: root
    
    property var banner
    property var dragProxy
    property var trans
    
    property bool stackExpanded: false
    property int index: 0
    property int count: 0

    function handleXChanged() {
        if (dragArea && dragArea.drag.active && !root.stackExpanded && root.index === 0) {
            NotificationManager.interactionDragPosition = dragProxy.x
        }
    }

    function handleReleased() {
        let dragVal = !root.stackExpanded ? NotificationManager.interactionDragPosition : dragProxy.x
        
        if (Math.abs(dragVal) > 100) {
            banner.removeHistory = true
            
            if (!root.stackExpanded && root.index === 0 && root.count > 1) {
                NotificationManager.clearAllNotifications()
                NotificationManager.interactionDragPosition = 0
            } else {
                trans.x = dragProxy.x
                dragProxy.x = 0 
                banner.dismiss()
            }
        } else {
            dragProxy.x = 0
            if (!root.stackExpanded) {
                NotificationManager.interactionDragPosition = 0
            }
        }
    }
}
