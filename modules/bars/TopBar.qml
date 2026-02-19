import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import QtQuick.Effects
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
    
    implicitHeight: FrameConfig.dynamicIslandExpandedHeight
    exclusiveZone: FrameConfig.thickness
    color: "transparent"

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
        height: FrameConfig.thickness
        color: FrameConfig.color
        z: 1
    }

    DynamicIsland {
        id: dIsland
        anchors.horizontalCenter: parent.horizontalCenter
        y: 0
        z: 2
        
        barHeight: FrameConfig.thickness
        barColor: FrameConfig.color
        activePlayer: root.activePlayer
        notifServer: notifServer
    }

    MouseArea {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: dIsland.expanded ? FrameConfig.dynamicIslandExpandedWidth : FrameConfig.dynamicIslandCollapsedWidth
        height: dIsland.expanded ? FrameConfig.dynamicIslandExpandedHeight : FrameConfig.thickness
        hoverEnabled: true
        onEntered: dIsland.expanded = true
        onExited: dIsland.expanded = false
        propagateComposedEvents: true
        onPressed: (mouse) => mouse.accepted = false
    }
}
