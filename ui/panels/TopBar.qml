import QtQuick
import QtQuick.Shapes
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

    implicitHeight: 300
    exclusiveZone: ThemeManager.globalThickness
    color: "transparent"
    focusable: dIsland.isExpanded

    mask: Region {
        Region {
            item: barRect
        }
        Region {
            item: dIslandHitbox
        }
        Region {
            item: ViewManager.hoveredWorkspaceId !== -1 ? workspacePreview : null
        }
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
                if (!dIsland.isExpanded) {
                    shrinkTimer.restart()
                } else {
                    shrinkTimer.stop()
                }
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

        WorkspaceIndicators {
            anchors.left: parent.left
            anchors.leftMargin: ThemeManager.globalCornerRadius + 15
            anchors.verticalCenter: parent.verticalCenter
            screenName: root.screen.name
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

    WorkspacePreview {
        id: workspacePreview
        screen: root.screen
        workspaceId: ViewManager.hoveredWorkspaceId
        visible: (ViewManager.hoveredWorkspaceId !== -1) && (ViewManager.lastActiveScreenName === root.screen.name)
        x: Math.max(ThemeManager.globalThickness + 8, ViewManager.hoveredWorkspaceX - (width / 4))
        y: ThemeManager.globalThickness + 8
        z: 5
    }
}
