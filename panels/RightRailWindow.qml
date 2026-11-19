import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.components
import qs.components.lifecycle
import qs.controlcenter
import qs.core
import qs.services.controlcenter
import qs.services.settings

PanelWindow {
    id: root

    readonly property string screenName: screen?.name ?? ""
    readonly property real bodyWidth: Math.max(0, Math.min(Design.controlBodyWidth, (screen?.width || 1920) - Design.controlRailWidth - Design.controlRailOuterGap * 2))
    readonly property real bodyHeight: Math.max(0, Math.min(Design.controlBodyHeight, (screen?.height || 1080) - Design.space24 * 2))
    readonly property real compactHeight: ControlCenterService.items.length * Design.controlRailButtonSize + (ControlCenterService.items.length - 1) * Design.controlRailItemGap + Design.space24
    readonly property bool bodyOpen: ControlCenterService.targetScreenName === screenName && ControlCenterService.opened
    property bool focusGrabEnabled: true
    property bool railShown: false
    property bool expandedGeometry: false
    property bool pageRetained: false
    property bool pageRevealed: false
    property real edgeOffset: railShown || bodyOpen ? Design.controlRailOuterGap : -Design.controlRailWidth - Design.controlRailOuterGap

    anchors.top: true
    anchors.bottom: true
    anchors.right: true
    implicitWidth: bodyWidth + Design.controlRailWidth + Design.controlRailOuterGap * 2
    color: "transparent"
    exclusiveZone: 0
    aboveWindows: true
    focusable: bodyOpen && focusGrabEnabled

    Behavior on edgeOffset {
        enabled: !Design.reducedMotion
        SpatialSpring {
            phase: root.railShown ? "enter" : "exit"
        }
    }

    function updateHover() {
        if (edgeHover.hovered || islandHover.hovered || bodyOpen) {
            hideTimer.stop();
            railShown = true;
        } else {
            hideTimer.restart();
        }
    }

    onBodyOpenChanged: {
        if (bodyOpen) {
            collapseTimer.stop();
            expandedGeometry = true;
            retireTimer.stop();
            pageRetained = true;
            revealTimer.restart();
        } else {
            revealTimer.stop();
            pageRevealed = false;
            collapseTimer.restart();
            retireTimer.restart();
        }
        updateHover();
    }

    Component.onCompleted: {
        if (bodyOpen) {
            expandedGeometry = true;
            pageRetained = true;
            pageRevealed = true;
        }
        updateHover();
    }

    Timer {
        id: hideTimer
        interval: Math.max(Design.controlRailHideDelay, Design.springViewRetireDelay)
        onTriggered: {
            if (!root.bodyOpen && !edgeHover.hovered && !islandHover.hovered)
                root.railShown = false;
        }
    }

    Timer {
        id: collapseTimer
        interval: Design.controlPageCollapseDelay
        onTriggered: {
            if (!root.bodyOpen)
                root.expandedGeometry = false;
        }
    }

    Timer {
        id: revealTimer
        interval: Design.controlPageRevealDelay
        onTriggered: root.pageRevealed = root.bodyOpen
    }

    Timer {
        id: retireTimer
        interval: Design.springViewRetireDelay
        onTriggered: {
            if (!root.bodyOpen)
                root.pageRetained = false;
        }
    }

    HyprlandFocusGrab {
        active: root.bodyOpen && root.focusGrabEnabled
        windows: [root]
        onCleared: ControlCenterService.close()
    }

    BackgroundEffect.blurRegion: Region {
        Region {
            item: blurParkingTarget
        }
        Region {
            item: (root.railShown || root.bodyOpen) && SettingsService.enableBlur ? islandGlass : null
            topLeftRadius: islandGlass.cornerRadius
            topRightRadius: islandGlass.cornerRadius
            bottomLeftRadius: islandGlass.cornerRadius
            bottomRightRadius: islandGlass.cornerRadius
        }
    }

    mask: Region {
        Region {
            item: edgeTrigger
        }
        Region {
            item: root.railShown || root.bodyOpen ? islandGlass : null
        }
    }

    Item {
        id: blurParkingTarget
        width: 1
        height: 1
        opacity: 0
    }

    Item {
        id: edgeTrigger
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: Design.controlRailEdgeWidth
        height: root.compactHeight + Design.space20
        opacity: 0

        HoverHandler {
            id: edgeHover
            onHoveredChanged: root.updateHover()
        }
    }

    GlassCard {
        id: islandGlass
        x: root.width - width - root.edgeOffset
        anchors.verticalCenter: parent.verticalCenter
        width: root.expandedGeometry ? root.bodyWidth + Design.controlRailWidth : Design.controlRailWidth
        height: root.expandedGeometry ? root.bodyHeight : root.compactHeight
        cornerRadius: root.expandedGeometry ? Design.radiusWorkspace : Design.controlRailWidth / 2
        backdropAvailable: SettingsService.enableBlur
        emphasis: root.expandedGeometry ? 1 : 0
        opacity: root.railShown || root.bodyOpen ? 1 : 0

        Behavior on width {
            enabled: !Design.reducedMotion
            SpatialSpring {
                phase: "morph"
            }
        }
        Behavior on height {
            enabled: !Design.reducedMotion
            SpatialSpring {
                phase: "morph"
            }
        }
        Behavior on cornerRadius {
            enabled: !Design.reducedMotion
            SpatialSpring {
                phase: "morph"
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: root.railShown ? Design.springEnterFadeDuration : Design.springExitFadeDuration
            }
        }
        Behavior on emphasis {
            NumberAnimation {
                duration: Design.motionStateDuration
            }
        }

        HoverHandler {
            id: islandHover
            onHoveredChanged: root.updateHover()
        }

        Item {
            id: pageViewport
            width: Math.max(0, parent.width - Design.controlRailWidth)
            height: parent.height
            clip: true
            visible: root.pageRetained
            opacity: root.pageRevealed ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: root.pageRevealed ? Design.springContentFadeInDuration : Design.springContentFadeOutDuration
                }
            }

            LifecycleLoader {
                x: pageViewport.width - root.bodyWidth
                width: root.bodyWidth
                height: parent.height
                resourceId: "control-center." + (ControlCenterService.currentItem || "none") + "." + root.screenName
                owner: "control-center"
                classification: "active-only"
                restorationSource: ControlCenterService.activeItem?.restorationSource || ""
                requestedActive: root.pageRetained && !!ControlCenterService.activeItem
                source: ControlCenterService.activeItem?.pageSource || ""
            }
        }

        Rectangle {
            x: parent.width - Design.controlRailWidth
            anchors.verticalCenter: parent.verticalCenter
            width: 1
            height: Math.max(0, parent.height - Design.space24 * 2)
            color: Theme.glassPanelStroke
            opacity: root.pageRevealed ? 0.55 : 0
        }

        Column {
            x: parent.width - Design.controlRailWidth + (Design.controlRailWidth - width) / 2
            anchors.verticalCenter: parent.verticalCenter
            spacing: Design.controlRailItemGap

            Repeater {
                model: ControlCenterService.items

                ControlRailButton {
                    required property var modelData
                    width: Design.controlRailButtonSize
                    height: Design.controlRailButtonSize
                    glyph: modelData.glyph
                    accessibleName: modelData.name
                    enabled: modelData.enabled
                    active: root.bodyOpen && ControlCenterService.currentItem === modelData.id
                    onActivated: {
                        if (active)
                            ControlCenterService.close();
                        else
                            ControlCenterService.openItem(modelData.id, root.screenName);
                    }
                }
            }
        }
    }
}
