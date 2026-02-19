import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import qs.config
import qs.components
import qs.modules.island
import "." 

Item {
    id: root
    
    property int barHeight: FrameConfig.thickness
    property color barColor: FrameConfig.color
    property var activePlayer: null
    property var notifServer: null
    
    property bool expanded: false
    property alias isInteracting: islandContainer.hovered
    property real blurAmount: 0
    property real radius: FrameConfig.dynamicIslandCornerRadius
    
    property real cornerHeight: 0

    states: [
        State {
            name: "expanded"
            when: root.expanded
            PropertyChanges { target: root; width: FrameConfig.dynamicIslandExpandedWidth; height: FrameConfig.dynamicIslandExpandedHeight; blurAmount: 0; cornerHeight: FrameConfig.roundedCornerShapeRadius }
            PropertyChanges { target: islandBodyMover; y: 4 } 
            PropertyChanges { target: islandContentArea; opacity: 1 }
        },
        State {
            name: "collapsed"
            when: !root.expanded
            PropertyChanges { target: root; width: FrameConfig.dynamicIslandCollapsedWidth; height: root.barHeight; blurAmount: 0.5; cornerHeight: 0 }
            PropertyChanges { target: islandBodyMover; y: 0 }
            PropertyChanges { target: islandContentArea; opacity: 0 }
        }
    ]

    transitions: [
        Transition {
            to: "expanded"
            ParallelAnimation {
                ParallelAnimation {
                    NumberAnimation {
                        properties: "width,height,blurAmount,cornerHeight"
                        duration: FrameConfig.animDuration
                        easing.type: FrameConfig.animEasing
                    }
                    NumberAnimation {
                        target: islandBodyMover
                        property: "y"
                        duration: FrameConfig.animDuration
                        easing.type: FrameConfig.animEasing
                    }
                }
                SequentialAnimation {
                    PauseAnimation { duration: FrameConfig.animDuration * 0.7 }
                    NumberAnimation {
                        target: islandContentArea
                        property: "opacity"
                        to: 1
                        duration: 150
                    }
                }
            }
        },
        Transition {
            to: "collapsed"
            SequentialAnimation {
                NumberAnimation {
                    target: islandContentArea
                    property: "opacity"
                    to: 0
                    duration: 100
                }
                ParallelAnimation {
                    NumberAnimation {
                        properties: "width,height,blurAmount"
                        duration: FrameConfig.animDuration
                        easing.type: FrameConfig.animEasing
                    }
                    NumberAnimation {
                        target: root
                        property: "cornerHeight"
                        to: 0
                        duration: FrameConfig.animDuration * 0.8
                        easing.type: FrameConfig.animEasing
                    }
                    NumberAnimation {
                        target: islandBodyMover
                        property: "y"
                        duration: FrameConfig.animDuration
                        easing.type: FrameConfig.animEasing
                    }
                }
            }
        }
    ]
    
    Item {
        id: islandContainer
        anchors.fill: parent
        
        readonly property bool isStatic: root.width === (root.expanded ? FrameConfig.dynamicIslandExpandedWidth : FrameConfig.dynamicIslandCollapsedWidth)
        
        property bool hovered: hoverHandler.hovered
        property bool dragging: view.dragging
        
        onHoveredChanged: root.expanded = hovered || dragging
        onDraggingChanged: root.expanded = hovered || dragging

        Item {
            id: islandBodyMover
            width: parent.width
            height: parent.height
            anchors.centerIn: parent

            Rectangle {
                anchors.fill: islandRect
                radius: root.radius
                color: "black"
                opacity: root.expanded && islandContainer.isStatic ? 0.4 : 0
                visible: opacity > 0
                z: -1
                layer.enabled: true
                layer.effect: MultiEffect { blurEnabled: true; blur: 0.6 }
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }

            RoundedCornerShape {
                anchors.right: islandRect.left
                anchors.rightMargin: -1
                anchors.top: islandRect.top
                anchors.topMargin: 16 
                width: FrameConfig.roundedCornerShapeWidth + 1
                height: root.cornerHeight
                isLeft: true
                isTop: true
                cornerRadius: FrameConfig.roundedCornerShapeRadius
                cornerColor: root.barColor
                opacity: root.cornerHeight > 1 ? 1.0 : 0.0
            }

            RoundedCornerShape {
                anchors.left: islandRect.right
                anchors.leftMargin: -1
                anchors.top: islandRect.top
                anchors.topMargin: 16 
                width: FrameConfig.roundedCornerShapeWidth + 1
                height: root.cornerHeight
                isTop: true
                cornerRadius: FrameConfig.roundedCornerShapeRadius
                cornerColor: root.barColor
                opacity: root.cornerHeight > 1 ? 1.0 : 0.0
            }

            ClippingRectangle {
                id: islandRect
                anchors.fill: parent
                color: root.barColor
                
                topLeftRadius: 0
                topRightRadius: 0
                bottomLeftRadius: root.radius
                bottomRightRadius: root.radius

                HoverHandler { id: hoverHandler }

                Item {
                    id: islandContentArea
                    anchors.fill: parent
                    opacity: 0 
                    clip: true
                    
                    layer.enabled: root.blurAmount > 0.01
                    layer.effect: MultiEffect {
                        blurEnabled: true
                        blur: root.blurAmount
                    }


                    Loader {
                        id: cavaLoader
                        anchors.bottom: indicatorsRow.top
                        anchors.bottomMargin: 14
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width - 40
                        height: 24
                        
                        readonly property bool musicPlaying: root.activePlayer && root.activePlayer.playbackState === MprisPlaybackState.Playing
                        readonly property bool musicTabActive: view.currentIndex === 1
                        
                        active: root.expanded && musicTabActive && musicPlaying
                        source: "Cava.qml"
                        visible: active && opacity > 0
                        opacity: active ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                    }

                    PathView {
                        id: view
                        anchors.fill: parent
                        anchors.topMargin: FrameConfig.pathViewTopMargin
                        anchors.bottom: indicatorsRow.top 
                        anchors.bottomMargin: FrameConfig.pathViewBottomMargin
                        
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
                                anchors.leftMargin: FrameConfig.delegateLoaderMargin
                                anchors.rightMargin: FrameConfig.delegateLoaderMargin
                                
                                sourceComponent: {
                                    if (model.type === "timeDate") return timeDateComp
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
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: FrameConfig.indicatorRowBottomMargin
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: FrameConfig.indicatorRowSpacing
                        opacity: view.visible ? 1 : 0
                        
                        Repeater { 
                            model: tabModel.count
                            Rectangle { 
                                width: view.currentIndex === index ? 12 : 4
                                height: 4
                                radius: 2
                                color: "white"
                                opacity: view.currentIndex === index ? 0.8 : 0.2
                                
                                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
                                Behavior on opacity { NumberAnimation { duration: 300 } }
                            } 
                        }
                    }
                }
            }
        }
    }
    
    Component { id: timeDateComp; TimeDate { } }
    Component { id: musicComp; Music { player: root.activePlayer } }
    Component { id: batteryComp; Battery {} }
    Component { id: notifComp; Notification { server: root.notifServer } }

    ListModel {
        id: tabModel
        Component.onCompleted: {
            append({ "type": "timeDate" })
            append({ "type": "music" })
            append({ "type": "notif" })
            append({ "type": "battery" }) 
        }
    }
}
