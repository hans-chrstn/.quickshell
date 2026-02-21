import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import qs.config
import qs.components

Item {
    id: root

    property bool expanded: false
    property int barHeight: FrameConfig.thickness
    property color barColor: FrameConfig.color
    property int expandedWidth: 400
    property int expandedHeight: 100
    property int collapsedWidth: 160
    property real radius: FrameConfig.dynamicIslandCornerRadius
    
    property real customTopLeftRadius: (root.isTop && !root.isCorner) ? 0 : root.radius
    property real customTopRightRadius: (root.isTop && !root.isCorner) ? 0 : root.radius
    property real customBottomLeftRadius: (root.isBottom && !root.isCorner) ? 0 : root.radius
    property real customBottomRightRadius: (root.isBottom && !root.isCorner) ? 0 : root.radius

    property bool isTop: true
    property bool isBottom: false
    property bool isCorner: false
    
    property color filletColor: root.barColor
    property real f1Rotation: 0
    property real f1X: -f1.fWidth + 1
    property real f1Y: 16
    property real f1TargetWidth: root.radius
    property real f1TargetHeight: root.radius

    property real f2Rotation: 90
    property real f2X: root.width - 1
    property real f2Y: 16
    property real f2TargetWidth: root.radius
    property real f2TargetHeight: root.radius

    property alias mouseHovered: hoverHandler.hovered
    default property alias content: islandContentArea.data

    states: [
        State {
            name: "expanded"
            when: root.expanded
            PropertyChanges { target: root; width: root.expandedWidth; height: root.expandedHeight }
            PropertyChanges { target: islandContentArea; opacity: 1 }
            PropertyChanges { target: f1; opacity: 1.0; fWidth: root.f1TargetWidth; fHeight: root.f1TargetHeight }
            PropertyChanges { target: f2; opacity: 1.0; fWidth: root.f2TargetWidth; fHeight: root.f2TargetHeight }
        },
        State {
            name: "collapsed"
            when: !root.expanded
            PropertyChanges { target: root; width: root.collapsedWidth; height: root.barHeight }
            PropertyChanges { target: islandContentArea; opacity: 0 }
            PropertyChanges { target: f1; opacity: 0.0; fWidth: 0; fHeight: 0 }
            PropertyChanges { target: f2; opacity: 0.0; fWidth: 0; fHeight: 0 }
        }
    ]

    transitions: [
        Transition {
            ParallelAnimation {
                NumberAnimation { targets: [root, f1, f2]; properties: "width,height,fWidth,fHeight"; duration: FrameConfig.animDuration; easing.type: FrameConfig.animEasing }
                NumberAnimation { targets: [f1, f2, islandContentArea]; property: "opacity"; duration: 150 }
            }
        }
    ]

    Item {
        id: islandContainer
        anchors.fill: parent

        Rectangle {
            anchors.fill: islandRect; radius: root.radius; color: "black"
            opacity: root.expanded && Math.abs(root.width - root.expandedWidth) < 1.0 ? 0.4 : 0
            visible: opacity > 0; z: -1
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowOpacity: FrameConfig.shadowOpacity
            shadowBlur: FrameConfig.shadowBlur / 30.0
            shadowVerticalOffset: FrameConfig.shadowVerticalOffset
        }
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }

        Item {
            id: f1
            property real fWidth: 0
            property real fHeight: 0
            width: fWidth; height: fHeight; opacity: 0; clip: true
            x: root.f1X; y: root.f1Y
            z: 100

            RoundedCornerShape {
                anchors.fill: parent
                isTop: true; isLeft: true
                rotation: root.f1Rotation
                cornerRadius: root.radius; cornerColor: root.filletColor
            }
        }

        Item {
            id: f2
            property real fWidth: 0
            property real fHeight: 0
            width: fWidth; height: fHeight; opacity: 0; clip: true
            x: root.f2X; y: root.f2Y
            z: 100

            RoundedCornerShape {
                anchors.fill: parent
                isTop: true; isLeft: true
                rotation: root.f2Rotation
                cornerRadius: root.radius; cornerColor: root.filletColor
            }
        }

        ClippingRectangle {
            id: islandRect; anchors.fill: parent; color: root.barColor
            topLeftRadius: root.customTopLeftRadius
            topRightRadius: root.customTopRightRadius
            bottomLeftRadius: root.customBottomLeftRadius
            bottomRightRadius: root.customBottomRightRadius
            
            HoverHandler { id: hoverHandler }
            Item { id: islandContentArea; anchors.fill: parent; opacity: 0; clip: false }
        }
    }
}
