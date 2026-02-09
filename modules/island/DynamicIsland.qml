import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import qs.config
import "." 

Item {
    id: root
    
    property int barHeight: 15
    property color barColor: "#222"
    property var activePlayer: null
    property var notifServer: null
    
    property bool expanded: false
    property alias isInteracting: islandContainer.hovered
    
    property real targetWidth: expanded ? 420 : 120
    property real targetHeight: expanded ? 130 : barHeight
    
    width: targetWidth
    height: targetHeight
    
    Behavior on width { NumberAnimation { duration: 350; easing.type: Easing.OutQuint } }
    Behavior on height { NumberAnimation { duration: 350; easing.type: Easing.OutQuint } }
    
    Item {
        id: islandContainer
        anchors.fill: parent
        
        property bool hovered: hoverHandler.hovered
        property bool dragging: view.dragging
        
        onHoveredChanged: root.expanded = hovered || dragging
        onDraggingChanged: root.expanded = hovered || dragging

        Shape {
            anchors.right: islandRect.left; anchors.top: parent.top; anchors.topMargin: root.barHeight
            width: 20; height: Math.min(20, Math.max(0, root.height - root.barHeight)); clip: true
            visible: root.height > (root.barHeight + 2)
            layer.enabled: true; layer.samples: 4
            ShapePath { strokeWidth: 0; fillColor: root.barColor; PathSvg { path: "M 0 0 L 20 0 L 20 20 A 20 20 0 0 0 0 0 Z" } }
        }
        Shape {
            anchors.left: islandRect.right; anchors.top: parent.top; anchors.topMargin: root.barHeight
            width: 20; height: Math.min(20, Math.max(0, root.height - root.barHeight)); clip: true
            visible: root.height > (root.barHeight + 2)
            layer.enabled: true; layer.samples: 4
            ShapePath { strokeWidth: 0; fillColor: root.barColor; PathSvg { path: "M 20 0 L 0 0 L 0 20 A 20 20 0 0 1 20 0 Z" } }
        }

        ClippingRectangle {
            id: islandRect
            anchors.centerIn: parent
            width: parent.width
            height: parent.height
            color: root.barColor
            
            topLeftRadius: 0
            topRightRadius: 0
            bottomLeftRadius: root.expanded ? 25 : 0
            bottomRightRadius: root.expanded ? 25 : 0
            
            Behavior on bottomLeftRadius { NumberAnimation { duration: 350; easing.type: Easing.OutQuint } }
            Behavior on bottomRightRadius { NumberAnimation { duration: 350; easing.type: Easing.OutQuint } }

            HoverHandler { id: hoverHandler }

            Item {
                id: islandContentArea
                anchors.fill: parent
                clip: true
                opacity: root.width > 350 ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 50 } }

                Row {
                    anchors.bottom: indicatorsRow.top; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: 15
                    height: 40; spacing: 4; opacity: 0.2 
                    visible: view.currentIndex === 0 && root.activePlayer && root.activePlayer.playbackState === MprisPlaybackState.Playing
                    Repeater {
                        model: 20 
                        Rectangle { width: (parent.width - (19 * 4)) / 20; height: parent.height * (0.2 + (0.6 * Math.random())); color: "white"; anchors.bottom: parent.bottom; radius: 2
                            Timer { interval: 100; running: parent.visible; repeat: true; onTriggered: parent.height = parent.parent.height * (0.2 + (0.6 * Math.random())) }
                            Behavior on height { NumberAnimation { duration: 100 } }
                        }
                    }
                }

                PathView {
                    id: view
                    anchors.fill: parent
                    anchors.topMargin: 10
                    anchors.bottom: indicatorsRow.top 
                    anchors.bottomMargin: 5
                    
                    visible: opacity > 0
                    model: tabModel
                    
                    pathItemCount: 3
                    snapMode: PathView.SnapOneItem
                    highlightRangeMode: PathView.StrictlyEnforceRange
                    preferredHighlightBegin: 0.5
                    preferredHighlightEnd: 0.5
                    dragMargin: width / 2
                    
                    path: Path {
                        startX: -view.width * 0.5
                        startY: view.height / 2
                        
                        PathAttribute { name: "itemOpacity"; value: 0.0 }
                        
                        PathLine { x: 0; y: view.height / 2 }
                        PathAttribute { name: "itemOpacity"; value: 0.0 }
                        
                        PathLine { x: view.width * 0.5; y: view.height / 2 }
                        PathAttribute { name: "itemOpacity"; value: 1.0 }
                        
                        PathLine { x: view.width; y: view.height / 2 }
                        PathAttribute { name: "itemOpacity"; value: 0.0 }
                        
                        PathLine { x: view.width * 1.5; y: view.height / 2 }
                        PathAttribute { name: "itemOpacity"; value: 0.0 }
                    }

                    delegate: Item {
                        width: view.width
                        height: view.height
                        
                        opacity: PathView.itemOpacity
                        
                        Loader {
                            anchors.fill: parent
                            anchors.leftMargin: 20
                            anchors.rightMargin: 20
                            
                            sourceComponent: {
                                if (model.type === "music") return musicComp
                                if (model.type === "battery") return batteryComp
                                if (model.type === "notif") return notifComp
                                return null
                            }
                        }
                    }
                }
                
                Row {
                    id: indicatorsRow
                    anchors.bottom: parent.bottom; anchors.bottomMargin: 8; anchors.horizontalCenter: parent.horizontalCenter; spacing: 6; opacity: view.visible ? 1 : 0
                    Repeater { model: tabModel.count; Rectangle { width: 6; height: 6; radius: 3; color: view.currentIndex === index ? "white" : "#555"; Behavior on color { ColorAnimation { duration: 150 } } } }
                }
            }
        }
    }
    
    Component { id: musicComp; MusicWidget { player: root.activePlayer } }
    Component { id: batteryComp; BatteryWidget {} }
    Component { id: notifComp; NotificationWidget { server: root.notifServer } }

    ListModel {
        id: tabModel
        Component.onCompleted: {
            append({ "type": "music" })
            append({ "type": "notif" })
            append({ "type": "battery" }) 
        }
    }
}
