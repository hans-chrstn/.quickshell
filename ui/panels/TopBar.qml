import QtQuick
import QtQuick.Shapes
import Quickshell
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

    implicitHeight: ThemeManager.dynamicIslandExpandedHeight
    exclusiveZone: ThemeManager.globalThickness
    color: "transparent"
    focusable: dIsland.isExpanded

    mask: Region {
        Region {
            item: barRect
        }
        Region {
            item: dIsland
        }
    }

    Rectangle {
        id: barRect
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: ThemeManager.globalThickness
        color: ThemeManager.backgroundColor
        z: 1

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
        z: 2

        barHeight: ThemeManager.globalThickness
        backgroundColor: ThemeManager.backgroundColor
    }
}
