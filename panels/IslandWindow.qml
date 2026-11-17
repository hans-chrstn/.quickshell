import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.island
import qs.core
import qs.services.island
import qs.services.settings

PanelWindow {
    id: root

    readonly property string screenName: root.screen?.name ?? ""
    readonly property bool zenMode: {
        const revision = IslandPresentationService.revision;
        return revision >= 0 && IslandPresentationService.isZenEnabled(screenName);
    }

    anchors.top: true
    anchors.left: true
    anchors.right: true

    implicitHeight: island.maximumExpandedHeight + 24
    exclusiveZone: 0
    color: "transparent"
    aboveWindows: true
    focusable: island.keyboardRequested

    HyprlandFocusGrab {
        active: !island.hidden && !island.compact && !island.ipcPinned
        windows: [root]
        onCleared: island.dispatch("outside")
    }

    BackgroundEffect.blurRegion: Region {
        Region {
            item: blurParkingTarget
        }

        Region {
            item: (island.hidden || !SettingsService.enableBlur) ? null : island.blurTarget
            topLeftRadius: island.cornerRadius
            topRightRadius: island.cornerRadius
            bottomLeftRadius: island.cornerRadius
            bottomRightRadius: island.cornerRadius
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
        Region {
            item: island
        }
        Region {
            item: edgeTrigger
        }
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

    TopIsland {
        id: island

        anchors.horizontalCenter: parent.horizontalCenter
        backdropAvailable: SettingsService.enableBlur
        zenMode: root.zenMode
        edgeHovered: edgeHover.hovered
        screenName: root.screenName
        availableWidth: root.screen?.width ?? root.width
        availableHeight: root.screen?.height ?? root.height
    }
}
