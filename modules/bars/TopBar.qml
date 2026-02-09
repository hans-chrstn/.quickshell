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

PanelWindow {
    id: root
    property var modelData
    screen: modelData
    
    anchors {
        top: true
        left: true
        right: true
    }
    
    property int barHeight: FrameConfig.thickness
    property color barColor: FrameConfig.color
    
    property bool expandedMode: false
    
    implicitHeight: expandedMode ? 130 : barHeight
    
    Timer {
        id: collapseTimer
        interval: 350 + 200
        onTriggered: root.expandedMode = false
    }

    exclusiveZone: barHeight
    color: "transparent"

    property var activePlayer: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null
    
    NotificationServer {
        id: notifServer
        bodySupported: true
        keepOnReload: false
        onNotification: (n) => n.tracked = true
    }

    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: barHeight
        color: barColor
    }

    DynamicIsland {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 0
        
        barHeight: root.barHeight
        barColor: root.barColor
        activePlayer: root.activePlayer
        notifServer: notifServer
        
        onExpandedChanged: {
            if (expanded) {
                root.expandedMode = true
                collapseTimer.stop()
            } else {
                collapseTimer.restart()
            }
        }
    }
}
