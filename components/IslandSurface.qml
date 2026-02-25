import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import qs.services
import qs.components

Item {
    id: root

    property bool isExpanded: false
    property int barHeight: ThemeManager.globalThickness
    property color backgroundColor: ThemeManager.backgroundPrimaryColor
    property int expandedWidth: 400
    property int expandedHeight: 100
    property int collapsedWidth: 160
    property real cornerRadius: ThemeManager.dynamicIslandCornerRadius
    
    property real topLeftRadius: (root.isAtTop && !root.isInCorner) ? 0 : root.cornerRadius
    property real topRightRadius: (root.isAtTop && !root.isInCorner) ? 0 : root.cornerRadius
    property real bottomLeftRadius: (root.isAtBottom && !root.isInCorner) ? 0 : root.cornerRadius
    property real bottomRightRadius: (root.isAtBottom && !root.isInCorner) ? 0 : root.cornerRadius

    property bool isAtTop: true
    property bool isAtBottom: false
    property bool isInCorner: false
    
    readonly property string screenName: (root.Window.window && root.Window.window.screen) ? root.Window.window.screen.name : ""

    onIsHoveredChanged: {
        if (isHovered && screenName !== "") {
            NotificationManager.activeScreenName = screenName
        }
    }
    
    property color filletColor: root.backgroundColor
    property real firstFilletRotation: 0
    property real firstFilletX: -cornerRadius + 1
    property real firstFilletY: 16

    property real secondFilletRotation: 90
    property real secondFilletX: root.width - 1
    property real secondFilletY: 16

    readonly property bool isHovered: hoverHandler.hovered
    default property alias surfaceContent: islandContentArea.data

    onIsExpandedChanged: {
        if (isExpanded) {
            SoundManager.playExpand()
        } else {
            SoundManager.playCollapse()
        }
    }

    states: [
        State {
            name: "expanded"
            when: root.isExpanded
            PropertyChanges { target: root; width: root.expandedWidth; height: root.expandedHeight }
            PropertyChanges { target: islandContentArea; opacity: 1 }
            PropertyChanges { target: firstFillet; opacity: 1.0 }
            PropertyChanges { target: secondFillet; opacity: 1.0 }
        },
        State {
            name: "collapsed"
            when: !root.isExpanded
            PropertyChanges { target: root; width: root.collapsedWidth; height: root.barHeight }
            PropertyChanges { target: islandContentArea; opacity: 0 }
            PropertyChanges { target: firstFillet; opacity: 0.0 }
            PropertyChanges { target: secondFillet; opacity: 0.0 }
        }
    ]

    transitions: [
        Transition {
            ParallelAnimation {
                NumberAnimation { 
                    targets: [root]
                    properties: "width,height"
                    duration: ThemeManager.animationDuration
                    easing.type: ThemeManager.animationEasing 
                }
                NumberAnimation { 
                    targets: [firstFillet, secondFillet, islandContentArea]
                    property: "opacity"
                    duration: 150 
                }
            }
        }
    ]

    Item {
        id: islandContainer
        anchors.fill: parent

        Rectangle {
            anchors.fill: islandRect
            radius: root.cornerRadius
            color: ThemeManager.shadowPrimaryColor
            opacity: root.isExpanded && Math.abs(root.width - root.expandedWidth) < 1.0 ? 0.4 : 0
            visible: opacity > 0
            z: -1
            
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowOpacity: ThemeManager.shadowOpacity
                shadowBlur: ThemeManager.shadowBlurRadius / 30.0
                shadowVerticalOffset: ThemeManager.shadowVerticalOffset
            }
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }

        FilletCorner {
            id: firstFillet
            isTop: true
            isLeft: true
            x: root.firstFilletX
            y: root.firstFilletY
            cornerRadius: root.cornerRadius
            cornerColor: root.filletColor
            filletRotation: root.firstFilletRotation
            opacity: 0
        }

        FilletCorner {
            id: secondFillet
            isTop: true
            isLeft: true
            x: root.secondFilletX
            y: root.secondFilletY
            cornerRadius: root.cornerRadius
            cornerColor: root.filletColor
            filletRotation: root.secondFilletRotation
            opacity: 0
        }

        ClippingRectangle {
            id: islandRect
            anchors.fill: parent
            color: root.backgroundColor
            topLeftRadius: root.topLeftRadius
            topRightRadius: root.topRightRadius
            bottomLeftRadius: root.bottomLeftRadius
            bottomRightRadius: root.bottomRightRadius
            
            HoverHandler { id: hoverHandler }
            Item { 
                id: islandContentArea
                anchors.fill: parent
                opacity: 0
                clip: false 
            }
        }
    }
}
