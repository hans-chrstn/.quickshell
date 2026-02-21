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
import qs.services

BaseBar {
    id: root
    
    anchors.top: true
    anchors.left: true
    anchors.right: true
    
    implicitHeight: FrameConfig.dynamicIslandExpandedHeight
    exclusiveZone: FrameConfig.thickness
    color: "transparent"
    focusable: dIsland.expanded

    mask: Region {
        Region { item: barRect }
        Region { item: dIsland }
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
        height: FrameConfig.thickness
        color: FrameConfig.color
        z: 1

        RowLayout {
            anchors.left: parent.left
            anchors.leftMargin: FrameConfig.cornerRadius + 15
            anchors.verticalCenter: parent.verticalCenter
            height: parent.height
            spacing: 6
            
            Repeater {
                model: NiriService.workspaces
                delegate: Rectangle {
                    readonly property bool onCurrentScreen: model.output === root.screen.name
                    visible: onCurrentScreen
                    
                    Layout.preferredWidth: visible ? (maWs.containsMouse ? 32 : (model.isActive ? 24 : 8)) : 0
                    Layout.preferredHeight: visible ? 6 : 0
                    
                    radius: 3
                    color: model.isFocused ? FrameConfig.accentColor : 
                           model.isActive ? Qt.rgba(1,1,1,0.5) : Qt.rgba(1,1,1,0.2)
                    
                    Behavior on color { ColorAnimation { duration: 200 } }
                    Behavior on Layout.preferredWidth { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
                    
                    MouseArea {
                        id: maWs
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: NiriService.focusWorkspace(model.id)
                    }
                }
            }
        }
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
