import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core
import qs.ui.panels
import qs.ui.features.island
import qs.ui.shared
import qs.ui.panels.bottombar

SystemPanel {
    id: root

    HoverHandler {
        onHoveredChanged: {
            if (hovered && root.screen) {
                ViewManager.trackScreen(root.screen.name)
            }
        }
    }

    implicitHeight: ThemeManager.appIslandExpandedHeight + ThemeManager.osdPillHeight + 40

    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: ThemeManager.globalThickness
    color: "transparent"

    focusable: true
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    mask: Region {
        Region {
            item: barRect
        }
        Region {
            item: islandTrigger
        }
        Region {
            item: (osdPill.isPillActive || osdShrinkTimer.running) ? osdMaskArea : null
        }
    }

    Timer {
        id: osdShrinkTimer
        interval: 350
    }

    Connections {
        target: osdPill
        function onIsPillActiveChanged() {
            if (!osdPill.isPillActive) {
                osdShrinkTimer.restart()
            } else {
                osdShrinkTimer.stop()
            }
        }
    }

    Rectangle {
        id: barRect
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: ThemeManager.globalThickness
        color: ThemeManager.backgroundColor
        z: 1
    }

    BottomBarTrigger {
        id: islandTrigger
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        targetIsland: appIsland
    }

    AppIsland {
        id: appIsland
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        z: 2

        barHeight: ThemeManager.globalThickness
        backgroundColor: ThemeManager.backgroundColor
    }

    BottomBarOSD {
        id: osdPill
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: appIsland.height + 20
        z: 5
        osdScreenName: root.screen ? root.screen.name : ""
    }

    Item {
        id: osdMaskArea
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        width: ThemeManager.osdPillWidth + 80
        height: ThemeManager.appIslandExpandedHeight + ThemeManager.osdPillHeight + 80
        opacity: 0
    }
}
