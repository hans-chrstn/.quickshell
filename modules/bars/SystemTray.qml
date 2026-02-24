import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import qs.services
import qs.components

Item {
    id: root
    width: 14
    height: ThemeService.thickness
    
    visible: SystemTrayService.count > 0

    Rectangle {
        id: indicatorPill
        anchors.centerIn: parent
        width: 10; height: 10; radius: 5
        
        readonly property var firstItem: SystemTrayService.values.length > 0 ? SystemTrayService.values[0] : null
        readonly property bool needsAttention: {
            for (let item of SystemTrayService.values) {
                if (item.status === SystemTrayItem.NeedsAttention) return true
            }
            return false
        }

        color: needsAttention ? ThemeService.dangerMain : 
               ((SystemTrayService.hoveredIndex !== -1) 
                ? Qt.rgba(ThemeService.backgroundContent.r, ThemeService.backgroundContent.g, ThemeService.backgroundContent.b, 1.0)
                : Qt.rgba(ThemeService.backgroundContent.r, ThemeService.backgroundContent.g, ThemeService.backgroundContent.b, 0.5))

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
            if (hovered) SystemTrayService.hoveredIndex = 0
            else unhoverTimer.restart()
        }
    }
    
    Timer {
        id: unhoverTimer
        interval: 350 
        onTriggered: if (!hh.hovered) SystemTrayService.hoveredIndex = -1
    }
}
