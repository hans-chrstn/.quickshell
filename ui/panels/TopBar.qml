import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris
import Quickshell.Services.Notifications
import qs.ui.features.island
import qs.core
import qs.ui.panels
import qs.ui.shared
import qs.ui.panels.topbar

SystemPanel {
    id: root

    anchors.top: true
    anchors.left: true
    anchors.right: true

    HoverHandler {
        onHoveredChanged: {
            if (hovered && root.screen) {
                ViewManager.trackScreen(root.screen.name)
            }
        }
    }

    implicitHeight: 600
    exclusiveZone: ThemeManager.globalThickness
    color: "transparent"
    focusable: dIsland.isExpanded

    mask: Region {
        Region { item: barRect }
        Region { item: islandMask }
        Region { item: previewMask }
        Region { item: ghostMask }
    }

    Item {
        id: islandMask
        anchors.horizontalCenter: dIsland.horizontalCenter
        y: dIsland.y
        width: (dIsland.isExpanded || shrinkTimer.running) ? dIsland.expandedWidth : 0
        height: (dIsland.isExpanded || shrinkTimer.running) ? dIsland.expandedHeight : 0
    }

    Item {
        id: previewMask
        x: workspacePreview.x
        y: workspacePreview.y
        width: (workspacePreview.active && workspacePreview.opacity > 0.1) ? workspacePreview.width : 0
        height: (workspacePreview.active && workspacePreview.opacity > 0.1) ? workspacePreview.height : 0
    }

    Item {
        id: ghostMask
        x: ghostWindow.x
        y: ghostWindow.y
        width: ghostWindow.visible ? ghostWindow.width : 0
        height: ghostWindow.visible ? ghostWindow.height : 0
    }

    Item {
        id: dIslandHitbox
        anchors.horizontalCenter: dIsland.horizontalCenter
        y: dIsland.y
        width: (dIsland.isExpanded || shrinkTimer.running) ? dIsland.expandedWidth : dIsland.collapsedWidth
        height: (dIsland.isExpanded || shrinkTimer.running) ? dIsland.expandedHeight : dIsland.barHeight
        opacity: 0

        Timer {
            id: shrinkTimer
            interval: ThemeManager.animationDuration + 50
        }

        Connections {
            target: dIsland
            function onIsExpandedChanged() {
                if (!dIsland.isExpanded) shrinkTimer.restart()
                else shrinkTimer.stop()
            }
        }
    }

    Rectangle {
        id: barRect
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: ThemeManager.globalThickness
        color: ThemeManager.backgroundColor
        z: 10

        HoverHandler {
            id: glideHandler
            onPointChanged: {
                let globalPos = barRect.mapToItem(null, point.position.x, 0)
                ViewManager.setHoveredWorkspace(-1, globalPos.x)
            }
            onHoveredChanged: {
                ViewManager.indicatorHovered = hovered
            }
        }

        WorkspaceIndicators {
            id: indicators
            anchors.left: parent.left
            anchors.leftMargin: ThemeManager.globalThickness + 12
            anchors.verticalCenter: parent.verticalCenter
            screenName: root.screen.name
            screen: root.screen
        }
    }

    DynamicIsland {
        id: dIsland
        anchors.horizontalCenter: parent.horizontalCenter
        y: 0
        z: 20
        barHeight: ThemeManager.globalThickness
        backgroundColor: ThemeManager.backgroundColor
    }

    property int _currentPreviewId: -1
    
    Connections {
        target: ViewManager
        function onHoveredWorkspaceIdChanged() {
            if (ViewManager.hoveredWorkspaceId !== -1) {
                root._currentPreviewId = ViewManager.hoveredWorkspaceId
            }
        }
    }

    WorkspacePreview {
        id: workspacePreview
        screen: root.screen
        workspaceId: root._currentPreviewId
        active: ViewManager.workspacePreviewActive && (ViewManager.lastActiveScreenName === root.screen.name)
        
        visible: true
        x: ThemeManager.globalThickness + 12
        y: ThemeManager.globalThickness + 8
        z: 5
    }

    Rectangle {
        id: ghostWindow
        width: 80
        height: 80
        radius: 16
        color: Qt.rgba(ThemeManager.accentColor.r, ThemeManager.accentColor.g, ThemeManager.accentColor.b, 0.6)
        border.color: "white"
        border.width: 2
        visible: ViewManager.activeDragWindowId !== -1 && (ViewManager.lastActiveScreenName === root.screen.name)
        
        x: (ViewManager.dragX - (root.screen ? root.screen.x : 0)) - (width / 2)
        y: (ViewManager.dragY - (root.screen ? root.screen.y : 0)) - (height / 2)
        z: 1000

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "black"
            shadowOpacity: 0.8
            shadowBlur: 0.5
        }

        Image {
            anchors.fill: parent
            anchors.margins: 16
            source: ViewManager.activeDragIcon ? "file://" + ViewManager.activeDragIcon : ""
            smooth: true
        }
    }
}
