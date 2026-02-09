import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import "."

BaseBar {
    id: root

    anchors.left: true
    anchors.top: true
    anchors.bottom: true

    margins.top: 0
    margins.bottom: 0

    readonly property int collapsedWidth: FrameConfig.thickness
    readonly property int triggerWidth: 60
    readonly property int sidebarWidth: 320
    readonly property int islandWidth: 280
    readonly property int islandHeight: 140

    implicitWidth: Math.max(sidebar.width, island.width, triggerWidth)

    exclusiveZone: collapsedWidth

    color: "transparent"
    
    mask: Region {
        Region { item: sidebar }
        Region { item: island }
        Region { item: topTriggerArea }
        Region { item: islandTriggerArea }
    }

    Rectangle {
        id: island
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        height: islandHeight
        
        property bool active: islandHandler.hovered && !sidebar.active
        
        width: active ? islandWidth : collapsedWidth
        
        Behavior on width {
            enabled: !sidebar.active 
            NumberAnimation {
                duration: FrameConfig.animDuration
                easing.type: FrameConfig.animEasing
                easing.overshoot: 0.8
            }
        }

        color: FrameConfig.color
        radius: 20
        
        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.radius
            color: parent.color
        }

        Item {
            anchors.fill: parent
            anchors.margins: 15
            opacity: island.width > (islandWidth * 0.8) ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 200 } }

            Row {
                anchors.centerIn: parent
                spacing: 15
                
                Rectangle {
                    width: 50; height: 50
                    radius: 8
                    color: "#ff0055"
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    Text { text: "Now Playing"; color: "#aaa"; font.pixelSize: 10 }
                    Text { text: "Song Title"; color: "white"; font.bold: true }
                }
            }
        }
    }

    Rectangle {
        id: sidebar
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        
        property bool active: (topHandler.hovered || (mainHandler.hovered && width > collapsedWidth * 2))
        
        width: active ? sidebarWidth : collapsedWidth
        Behavior on width {
            NumberAnimation {
                duration: 400
                easing.type: Easing.OutExpo
            }
        }

        color: FrameConfig.color
        radius: 20

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.radius
            color: parent.color
        }

        Item {
            anchors.fill: parent
            anchors.margins: 15
            opacity: sidebar.width > (sidebarWidth * 0.8) ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 200 } }

            Column {
                anchors.centerIn: parent
                width: parent.width
                spacing: 15
                
                Text {
                    text: "Sidebar Menu"
                    color: "white"
                    font.bold: true
                    font.pixelSize: 20
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                
                Repeater {
                    model: 6
                    Rectangle {
                        width: parent.width
                        height: 50
                        color: "#333"
                        radius: 8
                    }
                }
            }
        }
    }

    Item {
        anchors.fill: parent
        z: 100 
        
        Item {
            id: topTriggerArea
            anchors.left: parent.left
            anchors.top: parent.top
            width: triggerWidth 
            height: 150
            
            HoverHandler { id: topHandler }
        }

        Item {
            id: islandTriggerArea
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: triggerWidth
            height: islandHeight
            
            visible: !sidebar.active 
            HoverHandler { id: islandHandler }
        }

        Item {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: sidebar.width
            HoverHandler { id: mainHandler }
        }
    }
}
