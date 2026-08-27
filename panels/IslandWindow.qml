import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.island
import qs.core

PanelWindow {
    id: root

    anchors.top: true
    anchors.left: true
    anchors.right: true

    implicitHeight: island.maximumExpandedHeight + 24
    exclusiveZone: 0
    color: "transparent"
    aboveWindows: true
    focusable: island.keyboardRequested

    BackgroundEffect.blurRegion: Region {
        Region { item: blurParkingTarget }

        Region {
            item: island.hidden ? null : island.blurTarget
            topLeftRadius: 0
            topRightRadius: 0
            bottomLeftRadius: Design.bodyRadius
            bottomRightRadius: Design.bodyRadius
        }
    }

    Item {
        id: blurParkingTarget
        x: 0
        y: 0
        width: 1
        height: 1
        opacity: 0
    }

    mask: Region {
        Region { item: island }
        Region { item: edgeTrigger }
    }

    Item {
        id: edgeTrigger

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: island.collapsedWidth
        height: Design.triggerHeight
        opacity: 0

        HoverHandler {
            id: edgeHover
        }
    }

    DynamicIsland {
        id: island

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        edgeHovered: edgeHover.hovered
        screenName: root.screen?.name ?? ""
    }
}
