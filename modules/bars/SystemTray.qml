import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import qs.services
import qs.components

Item {
    id: root
    width: 14
    height: ThemeManager.globalThickness
    
    visible: SystemTrayManager.itemCount > 0

    Rectangle {
        id: indicatorPill
        anchors.centerIn: parent
        width: 10; height: 10; radius: 5
        
        readonly property var firstItem: SystemTrayManager.items.length > 0 ? SystemTrayManager.items[0] : null
        readonly property bool needsAttention: {
            for (let item of SystemTrayManager.items) {
                if (item.status === SystemTrayItem.NeedsAttention) return true
            }
            return false
        }

        color: needsAttention ? ThemeManager.dangerPrimaryColor : 
               ((SystemTrayManager.hoveredIndex !== -1) 
                ? Qt.rgba(ThemeManager.contentOnBackgroundColor.r, ThemeManager.contentOnBackgroundColor.g, ThemeManager.contentOnBackgroundColor.b, 1.0)
                : Qt.rgba(ThemeManager.contentOnBackgroundColor.r, ThemeManager.contentOnBackgroundColor.g, ThemeManager.contentOnBackgroundColor.b, 0.5))

        Behavior on color { ColorAnimation { duration: 300 } }

        SequentialAnimation on opacity {
            running: indicatorPill.needsAttention
            loops: Animation.Infinite
            NumberAnimation { from: 1.0; to: 0.4; duration: 800; easing.type: Easing.InOutSine }
            NumberAnimation { from: 0.4; to: 1.0; duration: 800; easing.type: Easing.InOutSine }
        }
    }

    HoverHandler { 
        id: hh
        onHoveredChanged: {
            if (hovered) SystemTrayManager.hoveredIndex = 0
            else unhoverTimer.restart()
        }
    }
    
    Timer {
        id: unhoverTimer
        interval: 350 
        onTriggered: if (!hh.hovered) SystemTrayManager.hoveredIndex = -1
    }
}
