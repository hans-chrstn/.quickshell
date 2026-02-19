import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import qs.config
import qs.components
import "." 

Item {
    id: root
    
    property int barHeight: FrameConfig.thickness
    property color barColor: FrameConfig.color
    property var activePlayer: null
    property var notifServer: null
    
    property bool expanded: false
    property alias isInteracting: islandContainer.hovered
    
    states: [
        State {
            name: "expanded"
            when: root.expanded
            PropertyChanges { target: root; width: FrameConfig.dynamicIslandExpandedWidth; height: FrameConfig.dynamicIslandExpandedHeight }
            PropertyChanges { target: islandContentArea; opacity: 1 }
        },
        State {
            name: "collapsed"
            when: !root.expanded
            PropertyChanges { target: root; width: FrameConfig.dynamicIslandCollapsedWidth; height: root.barHeight }
            PropertyChanges { target: islandContentArea; opacity: 0 }
        }
    ]

    transitions: [
        Transition {
            from: "collapsed"
            to: "expanded"
            NumberAnimation {
                properties: "width,height"
                duration: FrameConfig.animDuration
                easing.type: Easing.OutExpo
            }
            SequentialAnimation {
                PauseAnimation { duration: FrameConfig.animDuration * 0.5 }
                NumberAnimation {
                    target: islandContentArea
                    property: "opacity"
                    duration: FrameConfig.animDuration * 0.5
                }
            }
        },
        Transition {
            from: "expanded"
            to: "collapsed"
            NumberAnimation {
                properties: "width,height"
                duration: FrameConfig.animDuration
                easing.type: Easing.InExpo
            }
            NumberAnimation {
                target: islandContentArea
                property: "opacity"
                duration: FrameConfig.animDuration * 0.5
            }
        }
    ]
    
    Item {
        id: islandContainer
        anchors.fill: parent
        
        property bool hovered: hoverHandler.hovered
        property bool dragging: view.dragging
        
        onHoveredChanged: root.expanded = hovered || dragging
        onDraggingChanged: root.expanded = hovered || dragging

        RoundedCornerShape {
            anchors.right: islandRect.left
            anchors.top: parent.top
            anchors.topMargin: root.barHeight
            width: FrameConfig.roundedCornerShapeWidth
            height: Math.min(FrameConfig.roundedCornerShapeWidth, Math.max(0, root.height - root.barHeight))
            isLeft: true
            isTop: true
            cornerRadius: FrameConfig.roundedCornerShapeRadius
            cornerColor: root.barColor
            visible: root.height > (root.barHeight + 2)
        }

        RoundedCornerShape {
            anchors.left: islandRect.right
            anchors.top: parent.top
            anchors.topMargin: root.barHeight
            width: FrameConfig.roundedCornerShapeWidth
            height: Math.min(FrameConfig.roundedCornerShapeWidth, Math.max(0, root.height - root.barHeight))
            isTop: true
            cornerRadius: FrameConfig.roundedCornerShapeRadius
            cornerColor: root.barColor
            visible: root.height > (root.barHeight + 2)
        }

        ClippingRectangle {
            id: islandRect
            anchors.centerIn: parent
            width: parent.width
            height: parent.height
            color: root.barColor
            
            states: [
                State {
                    name: "expanded"
                    when: root.expanded
                    PropertyChanges { 
                        target: islandRect; 
                        topLeftRadius: 0; 
                        topRightRadius: 0;
                        bottomLeftRadius: FrameConfig.dynamicIslandCornerRadius; 
                        bottomRightRadius: FrameConfig.dynamicIslandCornerRadius 
                    }
                },
                State {
                    name: "collapsed"
                    when: !root.expanded
                    PropertyChanges { 
                        target: islandRect; 
                        topLeftRadius: 0; 
                        topRightRadius: 0;
                        bottomLeftRadius: 0; 
                        bottomRightRadius: 0 
                    }
                }
            ]

            transitions: [
                Transition {
                    from: "collapsed"
                    to: "expanded"
                    NumberAnimation {
                        properties: "topLeftRadius,topRightRadius,bottomLeftRadius,bottomRightRadius"
                        duration: FrameConfig.animDuration
                        easing.type: Easing.OutExpo
                    }
                },
                Transition {
                    from: "expanded"
                    to: "collapsed"
                    NumberAnimation {
                        properties: "topLeftRadius,topRightRadius,bottomLeftRadius,bottomRightRadius"
                        duration: FrameConfig.animDuration
                        easing.type: Easing.InExpo
                    }
                }
            ]

            HoverHandler { id: hoverHandler }

            Item {
                id: islandContentArea
                anchors.fill: parent
                clip: true


                Loader {
                    anchors.bottom: indicatorsRow.top; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: FrameConfig.cavaLoaderMargin
                    height: FrameConfig.cavaLoaderHeight
                    
                    readonly property bool musicPlaying: root.activePlayer && root.activePlayer.playbackState === MprisPlaybackState.Playing
                    readonly property bool musicTabActive: view.currentIndex === 1
                    
                    active: root.expanded && musicTabActive && musicPlaying
                    source: "Cava.qml"
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
                    anchors.bottomMargin: 10
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 6
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
