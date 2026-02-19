import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import "../config"

PanelWindow {
    id: root
    property var modelData
    screen: modelData
    readonly property string screenName: modelData ? modelData.name : ""

    property bool activeTop: false
    property bool activeBottom: false
    property bool activeLeft: false
    property bool activeRight: false

    property int sThick: FrameConfig.thickness
    property int iRadius: 10
    property int sRadius: sThick + iRadius
    property color sColor: FrameConfig.color
    
    property bool hoverEnabled: false
    property int expandedWidth: 200
    property int expandedHeight: 200
    readonly property bool hovered: hoverEnabled && hoverHandler.hovered
    
    property bool expandedState: false
    
    Timer {
        id: collapseTimer
        interval: 150
        onTriggered: root.expandedState = false
    }
    
    onHoveredChanged: {
        if (hovered) {
            root.expandedState = true
            collapseTimer.stop()
        } else {
            collapseTimer.restart()
        }
    }
    
    default property alias content: contentContainer.data

    anchors {
        top: activeTop
        bottom: activeBottom
        left: activeLeft
        right: activeRight
    }

    implicitWidth: hoverEnabled ? expandedWidth + FrameConfig.roundedCornerShapeRadius : sRadius
    implicitHeight: hoverEnabled ? expandedHeight + FrameConfig.roundedCornerShapeRadius : sRadius
    color: "transparent"
    
    exclusionMode: ExclusionMode.Ignore
    
    mask: Region {
        Region { item: container; intersection: Intersection.Combine }
        Region { item: verticalFillet; intersection: Intersection.Combine }
        Region { item: horizontalFillet; intersection: Intersection.Combine }
    }

    Item {
        id: container
        width: root.expandedState ? root.expandedWidth : root.sRadius
        height: root.expandedState ? root.expandedHeight : root.sRadius
        
        anchors.top: root.activeTop ? parent.top : undefined
        anchors.bottom: root.activeBottom ? parent.bottom : undefined
        anchors.left: root.activeLeft ? parent.left : undefined
        anchors.right: root.activeRight ? parent.right : undefined
        
        HoverHandler {
            id: hoverHandler
            enabled: root.hoverEnabled
        }

        readonly property bool isFullyExpanded: width === root.expandedWidth && height === root.expandedHeight
        readonly property bool isCollapsed: width === root.sRadius && height === root.sRadius

        Behavior on width { NumberAnimation { duration: FrameConfig.animDuration; easing.type: FrameConfig.animEasing } }
        Behavior on height { NumberAnimation { duration: FrameConfig.animDuration; easing.type: FrameConfig.animEasing } }

        Rectangle {
            anchors.fill: parent
            color: root.sColor
            opacity: root.expandedState ? 1.0 : (container.isCollapsed ? 0.0 : 1.0)
            radius: root.expandedState ? 15 : 0
            
            Behavior on opacity { NumberAnimation { duration: 150 } }
            Behavior on radius { NumberAnimation { duration: FrameConfig.animDuration } }
        }

        RoundedCornerShape {
            id: verticalFillet
            anchors.top: root.activeTop ? container.bottom : undefined
            anchors.bottom: root.activeBottom ? container.top : undefined
            anchors.left: root.activeLeft ? container.left : undefined
            anchors.right: root.activeRight ? container.right : undefined
            
            anchors.leftMargin: root.activeLeft ? root.sThick : 0
            anchors.rightMargin: root.activeRight ? root.sThick : 0
            
            width: root.sThick
            height: FrameConfig.roundedCornerShapeRadius
            
            isTop: root.activeTop
            isBottom: root.activeBottom
            isLeft: root.activeRight
            
            cornerRadius: FrameConfig.roundedCornerShapeRadius
            cornerColor: root.sColor
            opacity: root.expandedState ? 1.0 : (container.isCollapsed ? 0.0 : 1.0)
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }

        RoundedCornerShape {
            id: horizontalFillet
            anchors.left: root.activeLeft ? container.right : undefined
            anchors.right: root.activeRight ? container.left : undefined
            anchors.top: root.activeTop ? container.top : undefined
            anchors.bottom: root.activeBottom ? container.bottom : undefined
            
            anchors.topMargin: root.activeTop ? root.sThick : 0
            anchors.bottomMargin: root.activeBottom ? root.sThick : 0
            
            width: FrameConfig.roundedCornerShapeRadius
            height: root.sThick
            
            isTop: root.activeTop
            isBottom: root.activeBottom
            isLeft: root.activeRight
            
            cornerRadius: FrameConfig.roundedCornerShapeRadius
            cornerColor: root.sColor
            opacity: root.expandedState ? 1.0 : (container.isCollapsed ? 0.0 : 1.0)
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }

        Item {
            id: contentContainer
            anchors.fill: parent
            opacity: (root.hovered && container.isFullyExpanded) ? 1 : 0
            visible: opacity > 0
            
            Behavior on opacity { 
                NumberAnimation { 
                    duration: root.hovered ? 150 : 50
                } 
            }
        }

        Item {
            width: root.sRadius
            height: root.sRadius
            anchors.top: root.activeTop ? parent.top : undefined
            anchors.bottom: root.activeBottom ? parent.bottom : undefined
            anchors.left: root.activeLeft ? parent.left : undefined
            anchors.right: root.activeRight ? parent.right : undefined
            
            opacity: container.isCollapsed ? 1.0 : 0.0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 150 } }

            Shape {
                anchors.fill: parent
                visible: root.activeTop && root.activeLeft
                layer.enabled: true; layer.samples: 4
                ShapePath {
                    strokeWidth: 0; fillColor: root.sColor
                    PathSvg { path: "M 0 0 L 25 0 L 25 15 A 10 10 0 0 0 15 25 L 0 25 Z" }
                }
            }

            Shape {
                anchors.fill: parent
                visible: root.activeBottom && root.activeLeft
                layer.enabled: true; layer.samples: 4
                ShapePath {
                    strokeWidth: 0; fillColor: root.sColor
                    PathSvg { path: "M 0 25 L 25 25 L 25 10 A 10 10 0 0 1 15 0 L 0 0 Z" }
                }
            }

            Shape {
                anchors.fill: parent
                visible: root.activeTop && root.activeRight
                layer.enabled: true; layer.samples: 4
                ShapePath {
                    strokeWidth: 0; fillColor: root.sColor
                    PathSvg { path: "M 25 0 L 0 0 L 0 15 A 10 10 0 0 1 10 25 L 25 25 Z" }
                }
            }

            Shape {
                anchors.fill: parent
                visible: root.activeBottom && root.activeRight
                layer.enabled: true; layer.samples: 4
                ShapePath {
                    strokeWidth: 0; fillColor: root.sColor
                    PathSvg { path: "M 25 25 L 0 25 L 0 10 A 10 10 0 0 0 10 0 L 25 0 Z" }
                }
            }
        }
    }
}
