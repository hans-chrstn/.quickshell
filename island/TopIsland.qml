import QtQuick
import QtQuick.Effects
import qs.components
import qs.components.lifecycle
import qs.core
import qs.services.launcher
import qs.services.island
import qs.services.media
import qs.services.settings
import qs.services.shell
import qs.services.time
import qs.services.weather
import "TopIslandState.js" as State

FocusScope {
    id: root

    required property string screenName
    property bool edgeHovered: false
    property bool backdropAvailable: true
    property bool zenMode: false
    property bool ipcPinned: false
    property int availableWidth: 1920
    property int availableHeight: 1080
    property string motionPhase: "enter"
    property string displayPhase: "compact"
    property bool displayExpanded: false
    property string contentPhase: "compact"
    property real contentOpacity: 1
    property string pendingContentPhase: "compact"
    property var routeState: ({
            phase: "hidden",
            expanded: false
        })

    readonly property bool hidden: routeState.phase === "hidden"
    readonly property bool compact: routeState.phase === "compact"
    readonly property bool expanded: routeState.expanded
    readonly property bool keyboardRequested: !hidden && (hover.hovered || !compact)
    readonly property int collapsedWidth: SettingsService.topIslandCompactWidth
    readonly property int maximumExpandedHeight: Math.min(360, availableHeight - 30)
    readonly property real expansionProgress: displayPhase === "compact" ? 0 : 1
    readonly property Item blurTarget: surface
    readonly property real cornerRadius: surface.cornerRadius
    readonly property int targetWidth: Math.max(0, Math.min(availableWidth - 32, displayPhase === "compact" ? collapsedWidth : Math.round((displayPhase === "media" ? (displayExpanded ? 620 : 470) : displayExpanded ? 640 : 460) * SettingsService.topIslandExpandedScale / 100)))
    readonly property int targetHeight: displayPhase === "compact" ? 64 : displayPhase === "media" ? (displayExpanded ? 326 : 190) : displayPhase === "notifications" ? (displayExpanded ? 344 : 190) : (displayExpanded ? 356 : 230)

    width: targetWidth
    height: targetHeight
    y: hidden ? -targetHeight - 9 : 10
    opacity: hidden ? 0 : 1
    focus: keyboardRequested

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
    Behavior on y {
        enabled: !Design.reducedMotion
        SpatialSpring {
            phase: root.motionPhase
        }
    }
    Behavior on opacity {
        enabled: !Design.reducedMotion
        NumberAnimation {
            duration: root.hidden ? Design.springExitFadeDuration : Design.springEnterFadeDuration
            easing.type: Easing.InOutCubic
        }
    }
    Behavior on contentOpacity {
        enabled: !Design.reducedMotion
        NumberAnimation {
            duration: root.contentOpacity === 0 ? Design.springContentFadeOutDuration : Design.springContentFadeInDuration
            easing.type: Easing.InOutCubic
        }
    }

    function dispatch(kind, expanded = false, phase = "") {
        if (kind !== "open-route")
            ipcPinned = false;
        const next = State.reduce(routeState, {
            kind: kind,
            expanded: expanded,
            phase: phase
        });
        motionPhase = next.phase === "hidden" ? "exit" : routeState.phase === "hidden" ? "enter" : "morph";
        if (next.phase === "hidden") {
            contentSwitchTimer.stop();
            contentOpacity = 1;
            if (routeState.phase !== "hidden")
                retireTimer.restart();
        } else {
            retireTimer.stop();
            if (next.phase !== displayPhase) {
                pendingContentPhase = next.phase;
                contentOpacity = 0;
                contentSwitchTimer.restart();
            }
            displayPhase = next.phase;
            displayExpanded = next.expanded;
        }
        const openingLauncher = next.phase === "launcher" && routeState.phase !== "launcher" && !LauncherService.opened;
        const closingLauncher = routeState.phase === "launcher" && next.phase !== "launcher" && LauncherService.opened && LauncherService.targetScreenName === screenName;
        routeState = next;
        TopIslandCommandService.report(screenName, next);
        if (openingLauncher)
            LauncherService.open("", screenName);
        if (closingLauncher)
            LauncherService.close();
        if (next.phase === "hidden" || next.phase === "compact")
            TransientUiCoordinator.select(screenName, "island", "");
        else if (next.phase !== "compact")
            TransientUiCoordinator.select(screenName, "island", next.phase);
    }

    onEdgeHoveredChanged: {
        if (edgeHovered)
            dispatch("wake");
        else if (compact && !hover.hovered)
            hideTimer.restart();
    }

    onKeyboardRequestedChanged: {
        if (keyboardRequested)
            forceActiveFocus();
    }

    onHiddenChanged: syncConsumers()

    function syncConsumers() {
        ClockService.setConsumer("island.clock." + screenName, !hidden);
        WeatherService.setConsumer("island.weather." + screenName, !hidden);
        PlayerService.setConsumer("island.player." + screenName, !hidden);
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            dispatch("escape");
            event.accepted = true;
        } else if (routeState.phase === "launcher" && event.key === Qt.Key_Backspace) {
            LauncherService.query = LauncherService.query.slice(0, -1);
            event.accepted = true;
        } else if (routeState.phase === "launcher" && event.key === Qt.Key_Return) {
            LauncherService.executeSelected();
            event.accepted = true;
        } else if (routeState.phase === "launcher" && event.key === Qt.Key_Down) {
            LauncherService.moveSelection(1);
            event.accepted = true;
        } else if (routeState.phase === "launcher" && event.key === Qt.Key_Up) {
            LauncherService.moveSelection(-1);
            event.accepted = true;
        } else if ((root.compact || routeState.phase === "launcher") && event.text.length > 0 && event.text.charCodeAt(0) >= 32 && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))) {
            dispatch("type");
            LauncherService.query += event.text;
            event.accepted = true;
        }
    }

    Timer {
        id: hideTimer
        interval: Design.islandHoverLeaveDelay
        onTriggered: {
            if (root.compact && !root.ipcPinned && !hover.hovered && !root.edgeHovered)
                root.dispatch("hide");
        }
    }

    Timer {
        id: retireTimer
        interval: Design.springViewRetireDelay
        onTriggered: {
            if (root.hidden) {
                root.displayPhase = "compact";
                root.displayExpanded = false;
                root.contentPhase = "compact";
                root.contentOpacity = 1;
            }
        }
    }

    Timer {
        id: contentSwitchTimer
        interval: Design.reducedMotion ? 0 : Design.springContentSwapDelay
        onTriggered: {
            root.contentPhase = root.pendingContentPhase;
            root.contentOpacity = 1;
        }
    }

    HoverHandler {
        id: hover
        onHoveredChanged: {
            if (hovered) {
                hideTimer.stop();
                if (root.hidden)
                    root.dispatch("wake");
            } else if (root.compact && !root.edgeHovered) {
                hideTimer.restart();
            }
        }
    }

    Item {
        id: glassClip
        anchors.fill: parent
        layer.enabled: root.opacity > 0
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSpreadAtMin: 1
            maskThresholdMin: 0.5
            maskSource: ShaderEffectSource {
                sourceItem: Rectangle {
                    width: glassClip.width
                    height: glassClip.height
                    radius: surface.cornerRadius
                    color: Theme.textPrimary
                }
            }
        }

        GlassPanelSurface {
            id: surface
            anchors.fill: parent
            cornerRadius: root.displayPhase === "compact" ? 32 : SettingsService.topIslandCornerRadius
            backdropAvailable: root.backdropAvailable
            emphasis: root.expansionProgress

            Behavior on cornerRadius {
                enabled: !Design.reducedMotion
                SpatialSpring {
                    phase: "morph"
                }
            }
        }

        AudioLiquidField {
            anchors.fill: parent
            active: root.contentPhase === "compact" && PlayerService.playing && root.opacity > 0
            peak: PlayerService.peak
            cornerRadius: surface.cornerRadius
            opacity: root.contentOpacity
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton)
                    root.dispatch("right");
                else if (root.compact)
                    root.dispatch("left");
            }
        }

        TopIslandCompact {
            anchors.fill: parent
            visible: root.contentPhase === "compact"
            opacity: root.contentOpacity
            clip: true
        }

        LifecycleLoader {
            anchors.fill: parent
            resourceId: "island.media." + root.screenName
            owner: "top-island"
            classification: "active-only"
            restorationSource: "MPRIS player state"
            requestedActive: root.contentPhase === "media"
            opacity: root.contentOpacity
            clip: true
            sourceComponent: Component {
                TopIslandMedia {
                    expanded: root.displayExpanded
                }
            }
        }

        LifecycleLoader {
            anchors.fill: parent
            resourceId: "island.notifications." + root.screenName
            owner: "top-island"
            classification: "active-only"
            restorationSource: "notification service"
            requestedActive: root.contentPhase === "notifications"
            opacity: root.contentOpacity
            clip: true
            sourceComponent: Component {
                TopIslandNotifications {
                    expanded: root.displayExpanded
                }
            }
        }

        LifecycleLoader {
            anchors.fill: parent
            resourceId: "island.launcher." + root.screenName
            owner: "top-island"
            classification: "active-only"
            restorationSource: "desktop entries and launcher query"
            requestedActive: root.contentPhase === "launcher"
            opacity: root.contentOpacity
            clip: true
            sourceComponent: Component {
                TopIslandLauncher {
                    expanded: root.displayExpanded
                }
            }
        }
    }

    Connections {
        target: TopIslandCommandService
        function onRouteRequested(targetScreenName, route, expanded) {
            if (targetScreenName === root.screenName) {
                root.ipcPinned = true;
                root.dispatch("open-route", expanded, route);
            }
        }
        function onHideRequested(targetScreenName) {
            if (targetScreenName === root.screenName)
                root.dispatch("hide");
        }
    }

    Connections {
        target: LauncherService
        function onOpenedChanged() {
            if (LauncherService.opened && LauncherService.targetScreenName === root.screenName && root.routeState.phase !== "launcher")
                root.dispatch("open-launcher");
            else if (!LauncherService.opened && root.routeState.phase === "launcher")
                root.dispatch("launcher-closed");
        }
        function onTargetScreenNameChanged() {
            if (!LauncherService.opened)
                return;
            if (LauncherService.targetScreenName === root.screenName && root.routeState.phase !== "launcher")
                root.dispatch("open-launcher");
            else if (LauncherService.targetScreenName !== root.screenName && root.routeState.phase === "launcher")
                root.dispatch("launcher-closed");
        }
    }

    Connections {
        target: TransientUiCoordinator
        function onCloseAllRequested(reason) {
            root.dispatch("hide");
        }
    }

    Component.onCompleted: {
        syncConsumers();
        TopIslandCommandService.report(screenName, routeState);
    }

    Component.onDestruction: {
        ClockService.setConsumer("island.clock." + screenName, false);
        WeatherService.setConsumer("island.weather." + screenName, false);
        PlayerService.setConsumer("island.player." + screenName, false);
        TopIslandCommandService.forget(screenName);
    }
}
