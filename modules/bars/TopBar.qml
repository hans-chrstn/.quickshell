import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import Quickshell.Services.UPower
import Quickshell.Services.Notifications
import qs.modules.island
import qs.config
import qs.modules.bars

BaseBar {
    id: root
    
    anchors.top: true
    anchors.left: true
    anchors.right: true
    
    property int barHeight: FrameConfig.thickness
    property bool expandedMode: false
    
    implicitHeight: expandedMode ? FrameConfig.dynamicIslandExpandedHeight : barHeight
    
    Timer {
        id: collapseTimer
        interval: FrameConfig.animDuration + FrameConfig.collapseTimerDelay
        onTriggered: root.expandedMode = false
    }

    exclusiveZone: barHeight
    color: "transparent"

    mask: Region {
        Region { item: barRect; intersection: Intersection.Combine }
        Region { item: dIsland; intersection: Intersection.Combine }
    }

    property var activePlayer: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null
    
    NotificationServer {
        id: notifServer
        bodySupported: true
        keepOnReload: false
        onNotification: (n) => n.tracked = true
    }

    Rectangle {
        id: barRect
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: barHeight
        color: FrameConfig.color
    }

    DynamicIsland {
        id: dIsland
        anchors.horizontalCenter: parent.horizontalCenter
        y: 0
        
        barHeight: root.barHeight
        barColor: FrameConfig.color
        activePlayer: root.activePlayer
        notifServer: notifServer
        
        onExpandedChanged: {
            if (expanded) {
                root.expandedMode = true
                collapseTimer.stop()
            }
            else {
                collapseTimer.restart()
            }
        }
    }
}
