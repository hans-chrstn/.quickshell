import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import qs.core
import qs.ui.shared

PanelWindow {
    id: root
    
    property alias modelData: root.screen
    readonly property string screenIdentifier: screen ? screen.name : ""

    property alias contentIsland: island

    property bool isAtTop: false
    property bool isAtBottom: false
    property bool isAtLeft: false
    property bool isAtRight: false

    property int surfaceThickness: ThemeManager.globalThickness
    property int innerCornerRadius: 10
    property int surfaceCornerRadius: surfaceThickness + innerCornerRadius
    property color surfaceBackgroundColor: ThemeManager.backgroundColor
    
    property bool isHoverEnabled: false
    property int expandedWidth: 200
    property int expandedHeight: 200
    readonly property bool isHovered: isHoverEnabled && island.isHovered
    
    property bool isExpanded: false
    
    property color filletColor: surfaceBackgroundColor
    property real firstFilletRotation: 0
    property real firstFilletX: 0
    property real firstFilletY: 0
    property real secondFilletRotation: 0
    property real secondFilletX: 0
    property real secondFilletY: 0

    property var customTopLeftRadius: undefined
    property var customTopRightRadius: undefined
    property var customBottomLeftRadius: undefined
    property var customBottomRightRadius: undefined

    default property alias surfaceContent: island.surfaceContent

    anchors {
        top: isAtTop
        bottom: isAtBottom
        left: isAtLeft
        right: isAtRight
    }

    implicitWidth: isHoverEnabled ? expandedWidth + 40 : surfaceCornerRadius
    implicitHeight: isHoverEnabled ? expandedHeight + 40 : surfaceCornerRadius
    color: "transparent"
    
    exclusionMode: ExclusionMode.Ignore
    
    mask: Region {
        Region { 
            item: island 
        }
        Region { 
            item: cornerVisualBox 
        }
    }

    IslandSurface {
        id: island
        anchors.top: root.isAtTop ? parent.top : undefined
        anchors.bottom: root.isAtBottom ? parent.bottom : undefined
        anchors.left: root.isAtLeft ? parent.left : undefined
        anchors.right: root.isAtRight ? parent.right : undefined
        
        isInCorner: true
        isAtTop: root.isAtTop
        isAtBottom: root.isAtBottom
        
        isExpanded: root.isExpanded
        expandedWidth: root.expandedWidth
        expandedHeight: root.expandedHeight
        collapsedWidth: root.surfaceCornerRadius
        barHeight: root.surfaceCornerRadius
        backgroundColor: root.surfaceBackgroundColor
        filletColor: root.filletColor
        
        firstFilletRotation: root.firstFilletRotation
        firstFilletX: root.firstFilletX
        firstFilletY: root.firstFilletY

        secondFilletRotation: root.secondFilletRotation
        secondFilletX: root.secondFilletX
        secondFilletY: root.secondFilletY

        topLeftRadius: root.customTopLeftRadius !== undefined ? root.customTopLeftRadius : ((root.isAtTop && !root.isInCorner) ? 0 : ThemeManager.globalCornerRadius)
        topRightRadius: root.customTopRightRadius !== undefined ? root.customTopRightRadius : ((root.isAtTop && !root.isInCorner) ? 0 : ThemeManager.globalCornerRadius)
        bottomLeftRadius: root.customBottomLeftRadius !== undefined ? root.customBottomLeftRadius : ((root.isAtBottom && !root.isInCorner) ? 0 : ThemeManager.globalCornerRadius)
        bottomRightRadius: root.customBottomRightRadius !== undefined ? root.customBottomRightRadius : ((root.isAtBottom && !root.isInCorner) ? 0 : ThemeManager.globalCornerRadius)

        opacity: root.isExpanded ? 1.0 : 0.0
        Behavior on opacity { 
            NumberAnimation { 
                duration: 150 
            } 
        }
    }

    Item {
        id: cornerVisualBox
        width: root.surfaceCornerRadius
        height: root.surfaceCornerRadius
        anchors.top: root.isAtTop ? parent.top : undefined
        anchors.bottom: root.isAtBottom ? parent.bottom : undefined
        anchors.left: root.isAtLeft ? parent.left : undefined
        anchors.right: root.isAtRight ? parent.right : undefined
        opacity: root.isExpanded ? 0.0 : 1.0
        Behavior on opacity { 
            NumberAnimation { 
                duration: 150 
            } 
        }
        
        Shape {
            anchors.fill: parent
            visible: root.isAtTop && root.isAtLeft
            layer.enabled: true
            layer.samples: 4
            ShapePath { 
                strokeWidth: 0
                fillColor: root.surfaceBackgroundColor
                PathSvg { 
                    path: "M 0 0 L 25 0 L 25 15 A 10 10 0 0 0 15 25 L 0 25 Z" 
                } 
            }
        }
        Shape { 
            anchors.fill: parent
            visible: root.isAtBottom && root.isAtLeft
            layer.enabled: true
            layer.samples: 4
            ShapePath { 
                strokeWidth: 0
                fillColor: root.surfaceBackgroundColor
                PathSvg { 
                    path: "M 0 25 L 25 25 L 25 10 A 10 10 0 0 1 15 0 L 0 0 Z" 
                } 
            } 
        }
        Shape { 
            anchors.fill: parent
            visible: root.isAtTop && root.isAtRight
            layer.enabled: true
            layer.samples: 4
            ShapePath { 
                strokeWidth: 0
                fillColor: root.surfaceBackgroundColor
                PathSvg { 
                    path: "M 25 0 L 0 0 L 0 15 A 10 10 0 0 1 10 25 L 25 25 Z" 
                } 
            } 
        }
        Shape { 
            anchors.fill: parent
            visible: root.isAtBottom && root.isAtRight
            layer.enabled: true
            layer.samples: 4
            ShapePath { 
                strokeWidth: 0
                fillColor: root.surfaceBackgroundColor
                PathSvg { 
                    path: "M 25 25 L 0 25 L 0 10 A 10 10 0 0 0 10 0 L 25 0 Z" 
                } 
            } 
        }
    }

    Timer { 
        id: collapseTimer
        interval: 150
        onTriggered: {
            root.isExpanded = false
        }
    }
    
    onIsHoveredChanged: { 
        if (isHovered) { 
            root.isExpanded = true
            collapseTimer.stop() 
        } else { 
            collapseTimer.restart() 
        } 
    }
}
