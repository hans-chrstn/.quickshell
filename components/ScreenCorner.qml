import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import Quickshell
import QtQuick.Layouts
import Quickshell.Wayland
import qs.config
import qs.components

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
    readonly property bool hovered: hoverEnabled && island.mouseHovered
    
    property bool expandedState: false
    
    property color filletColor: sColor
    property real f1Rot: 0
    property real f1X: 0
    property real f1Y: 0
    property real f2Rot: 0
    property real f2X: 0
    property real f2Y: 0

    property var customTL: undefined
    property var customTR: undefined
    property var customBL: undefined
    property var customBR: undefined

    default property alias content: island.content

    anchors {
        top: activeTop
        bottom: activeBottom
        left: activeLeft
        right: activeRight
    }

    implicitWidth: hoverEnabled ? expandedWidth + 40 : sRadius
    implicitHeight: hoverEnabled ? expandedHeight + 40 : sRadius
    color: "transparent"
    
    exclusionMode: ExclusionMode.Ignore
    
    mask: Region {
        Region { item: island }
        Region { item: cornerIconBox }
    }

    BaseIsland {
        id: island
        anchors.top: root.activeTop ? parent.top : undefined
        anchors.bottom: root.activeBottom ? parent.bottom : undefined
        anchors.left: root.activeLeft ? parent.left : undefined
        anchors.right: root.activeRight ? parent.right : undefined
        
        isCorner: true
        isTop: root.activeTop
        isBottom: root.activeBottom
        
        expanded: root.expandedState
        expandedWidth: root.expandedWidth
        expandedHeight: root.expandedHeight
        collapsedWidth: root.sRadius
        barHeight: root.sRadius
        barColor: root.sColor
        filletColor: root.filletColor
        
        f1Rotation: root.f1Rot
        f1X: root.f1X
        f1Y: root.f1Y

        f2Rotation: root.f2Rot
        f2X: root.f2X
        f2Y: root.f2Y

        customTopLeftRadius: root.customTL !== undefined ? root.customTL : ((root.activeTop && !root.isCorner) ? 0 : root.radius)
        customTopRightRadius: root.customTR !== undefined ? root.customTR : ((root.activeTop && !root.isCorner) ? 0 : root.radius)
        customBottomLeftRadius: root.customBL !== undefined ? root.customBL : ((root.activeBottom && !root.isCorner) ? 0 : root.radius)
        customBottomRightRadius: root.customBR !== undefined ? root.customBR : ((root.activeBottom && !root.isCorner) ? 0 : root.radius)

        opacity: root.expandedState ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }

    Item {
        id: cornerIconBox
        width: root.sRadius; height: root.sRadius
        anchors.top: root.activeTop ? parent.top : undefined
        anchors.bottom: root.activeBottom ? parent.bottom : undefined
        anchors.left: root.activeLeft ? parent.left : undefined
        anchors.right: root.activeRight ? parent.right : undefined
        opacity: root.expandedState ? 0.0 : 1.0
        Behavior on opacity { NumberAnimation { duration: 150 } }
        
        Shape {
            anchors.fill: parent
            visible: root.activeTop && root.activeLeft
            layer.enabled: true; layer.samples: 4
            ShapePath { strokeWidth: 0; fillColor: root.sColor; PathSvg { path: "M 0 0 L 25 0 L 25 15 A 10 10 0 0 0 15 25 L 0 25 Z" } }
        }
        Shape { anchors.fill: parent; visible: root.activeBottom && root.activeLeft; layer.enabled: true; layer.samples: 4; ShapePath { strokeWidth: 0; fillColor: root.sColor; PathSvg { path: "M 0 25 L 25 25 L 25 10 A 10 10 0 0 1 15 0 L 0 0 Z" } } }
        Shape { anchors.fill: parent; visible: root.activeTop && root.activeRight; layer.enabled: true; layer.samples: 4; ShapePath { strokeWidth: 0; fillColor: root.sColor; PathSvg { path: "M 25 0 L 0 0 L 0 15 A 10 10 0 0 1 10 25 L 25 25 Z" } } }
        Shape { anchors.fill: parent; visible: root.activeBottom && root.activeRight; layer.enabled: true; layer.samples: 4; ShapePath { strokeWidth: 0; fillColor: root.sColor; PathSvg { path: "M 25 25 L 0 25 L 0 10 A 10 10 0 0 0 10 0 L 25 0 Z" } } }
    }

    Timer { id: collapseTimer; interval: 150; onTriggered: root.expandedState = false }
    onHoveredChanged: { if (hovered) { root.expandedState = true; collapseTimer.stop() } else { collapseTimer.restart() } }
}
