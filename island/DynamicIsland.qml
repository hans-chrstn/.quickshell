import QtQuick
import Quickshell
import qs.core
import qs.components
import qs.modules.clock
import qs.modules.launcher
import qs.modules.notifications
import qs.modules.session
import qs.modules.settings
import qs.services.island
import "../core/IslandSizing.js" as IslandSizing

Item {
    id: root

    property alias blurTarget: backgroundBlurTarget

    readonly property int hiddenState: 0
    readonly property int collapsedState: 1
    readonly property int expandedState: 2

    property int presentationState: hiddenState
    property bool edgeHovered: false
    property bool attentionRequested: false
    property string screenName: ""
    property real availableWidth: 0
    property real availableHeight: 0
    property IslandModule presentedModule: null
    property string registeredSizingScreenName: ""
    readonly property bool keyboardRequested: registry.current?.wantsKeyboard ?? false

    ModuleRegistry {
        id: registry
        modules: [
            ClockModuleSpec {},
            NotificationModuleSpec {
                screenName: root.screenName
            },
            LauncherModuleSpec {
                screenName: root.screenName
            },
            SettingsModuleSpec {
                screenName: root.screenName
            },
            SessionModuleSpec {
                screenName: root.screenName
            }
        ]
    }

    function synchronizePresentedModule() {
        const candidate = registry.current
        if (!candidate || candidate === presentedModule)
            return

        if (!presentedModule
                || candidate.priority >= presentedModule.priority
                || (!expanded && expansionProgress <= 0.001)) {
            presentedModule = candidate
        }
    }

    Connections {
        target: registry
        function onCurrentChanged() {
            root.synchronizePresentedModule()
        }
    }

    Component.onCompleted: synchronizePresentedModule()

    readonly property var sizingBounds: ({
        availableWidth: Math.max(0, availableWidth),
        availableHeight: Math.max(0, availableHeight)
    })
    readonly property int legacyCollapsedWidth:
        presentedModule?.collapsedWidth ?? Design.collapsedWidth
    readonly property int legacyCollapsedHeight: Design.collapsedHeight
    readonly property int legacyExpandedWidth:
        presentedModule?.expandedWidth ?? Design.defaultExpandedWidth
    readonly property int legacyExpandedHeight:
        presentedModule?.expandedHeight ?? Design.defaultExpandedHeight
    readonly property var collapsedSizing: IslandSizing.resolve(
        presentedModule?.collapsedSize, sizingBounds, {
            width: legacyCollapsedWidth,
            height: legacyCollapsedHeight
        }, {
            width: contentHost.collapsedImplicitWidth
                + 2 * (Design.wing + Design.contentHorizontalPadding),
            height: contentHost.collapsedImplicitHeight
                + 2 * Design.contentVerticalPadding
        })
    readonly property var expandedSizing: IslandSizing.resolve(
        presentedModule?.expandedSize, sizingBounds, {
            width: legacyExpandedWidth,
            height: legacyExpandedHeight
        }, {
            width: contentHost.expandedImplicitWidth
                + 2 * (Design.wing + Design.expandedContentPadding),
            height: contentHost.expandedImplicitHeight
                + 2 * Design.expandedContentPadding
        })
    readonly property var sizingDiagnostic: ({
        moduleId: presentedModule?.moduleId ?? "none",
        availableWidth: sizingBounds.availableWidth,
        availableHeight: sizingBounds.availableHeight,
        collapsed: collapsedSizing,
        expanded: expandedSizing,
        appliedToGeometry: presentedModule?.collapsedSize.source
                === "intrinsic"
            || presentedModule?.expandedSize.source === "intrinsic"
    })

    function publishSizingDiagnostic() {
        const name = String(screenName || "").trim()
        if (registeredSizingScreenName.length > 0
                && registeredSizingScreenName !== name) {
            IslandSizingService.remove(registeredSizingScreenName)
        }
        registeredSizingScreenName = name
        if (name.length > 0)
            IslandSizingService.report(name, sizingDiagnostic)
    }

    onSizingDiagnosticChanged: publishSizingDiagnostic()
    onScreenNameChanged: publishSizingDiagnostic()
    Component.onDestruction:
        IslandSizingService.remove(registeredSizingScreenName)

    readonly property int maximumExpandedHeight: {
        let maximum = Design.defaultExpandedHeight;
        for (let module of registry.modules)
            maximum = Math.max(maximum, module?.expandedHeight ?? 0);
        return maximum;
    }

    Connections {
        target: registry
        function onAttentionRequestedChanged() {
            root.attentionRequested = registry.attentionRequested;
            if (root.attentionRequested) {
                hideTimer.stop();
                if (root.expanded) {
                    attentionExpandTimer.stop();
                } else {
                    root.reveal(false);
                    attentionExpandTimer.restart();
                }
            } else {
                attentionExpandTimer.stop();
                expandTimer.stop();
                hideTimer.stop();
                root.presentationState = root.pointerPresent ? root.expandedState : root.collapsedState;
                moduleHandoffTimer.restart();
            }
        }
    }

    Timer {
        id: attentionExpandTimer
        interval: Design.attentionExpandDelay
        onTriggered: if (root.attentionRequested)
            root.reveal(true)
    }

    Timer {
        id: moduleHandoffTimer
        interval: Design.moduleHandoffDuration
        onTriggered: root.reconsider()
    }

    readonly property bool hidden: presentationState === hiddenState
    readonly property bool expanded: presentationState === expandedState
    readonly property bool pointerPresent: edgeHovered || islandHover.hovered
    readonly property bool returningToClock: presentedModule !== null
        && presentedModule.moduleId !== "clock"
        && !expanded && !presentedModule.attention
    property real expansionProgress: expanded ? 1 : 0

    Behavior on expansionProgress {
        NumberAnimation {
            duration: Design.resizeDuration
            easing.type: Design.islandMorphEasing
        }
    }

    onExpansionProgressChanged: synchronizePresentedModule()

    property int collapsedWidth: presentedModule?.collapsedSize.source
            === "intrinsic" && collapsedSizing.measurementReady
        ? Math.round(collapsedSizing.resolvedWidth) : legacyCollapsedWidth
    property int collapsedHeight: presentedModule?.collapsedSize.source
            === "intrinsic" && collapsedSizing.measurementReady
        ? Math.round(collapsedSizing.resolvedHeight) : legacyCollapsedHeight
    property int expandedWidth: presentedModule?.expandedSize.source
            === "intrinsic" && expandedSizing.measurementReady
        ? Math.round(expandedSizing.resolvedWidth) : legacyExpandedWidth
    property int expandedHeight: presentedModule?.expandedSize.source
            === "intrinsic" && expandedSizing.measurementReady
        ? Math.round(expandedSizing.resolvedHeight) : legacyExpandedHeight

    width: expanded ? expandedWidth : collapsedWidth
    height: expanded ? expandedHeight : collapsedHeight

    transform: Translate {
        y: root.hidden ? -(root.height + Design.wing) : 0
        Behavior on y {
            NumberAnimation {
                duration: Design.revealDuration
                easing.type: Easing.InOutCubic
            }
        }
    }

    Behavior on width {
        NumberAnimation {
            duration: Design.resizeDuration
            easing.type: Design.islandMorphEasing
        }
    }

    Behavior on height {
        NumberAnimation {
            duration: Design.resizeDuration
            easing.type: Design.islandMorphEasing
        }
    }

    function reveal(expand) {
        hideTimer.stop();
        presentationState = expand ? expandedState : collapsedState;
    }

    function requestAttention(duration) {
        attentionRequested = true;
        reveal(true);
        attentionTimer.interval = Math.max(500, duration || 2500);
        attentionTimer.restart();
    }

    function reconsider() {
        if (pointerPresent || attentionRequested) {
            hideTimer.stop();
            if (hidden)
                presentationState = collapsedState;
            if (pointerPresent)
                expandTimer.restart();
        } else {
            expandTimer.stop();
            presentationState = collapsedState;
            hideTimer.restart();
        }
    }

    onPointerPresentChanged: reconsider()

    Timer {
        id: expandTimer
        interval: Design.expandDelay
        onTriggered: if (root.pointerPresent)
            root.presentationState = root.expandedState
    }

    Timer {
        id: hideTimer
        interval: Design.hideDelay
        onTriggered: if (!root.pointerPresent && !root.attentionRequested)
            root.presentationState = root.hiddenState
    }

    Timer {
        id: attentionTimer
        onTriggered: {
            root.attentionRequested = false;
            root.reconsider();
        }
    }

    Item {
        id: backgroundBlurTarget
        anchors.fill: parent
        anchors.leftMargin: Design.wing
        anchors.rightMargin: Design.wing
        visible: true
        opacity: 0
    }

    GlassIslandSurface {
        anchors.fill: parent
        expanded: root.expanded
        expansionProgress: root.expansionProgress
    }

    HoverHandler {
        id: islandHover
    }

    Item {
        id: contentViewport
        anchors.fill: parent
        anchors.leftMargin: Design.wing + Design.contentHorizontalPadding + (Design.expandedContentPadding - Design.contentHorizontalPadding) * root.expansionProgress
        anchors.rightMargin: anchors.leftMargin
        anchors.topMargin: Design.contentVerticalPadding + (Design.expandedContentPadding - Design.contentVerticalPadding) * root.expansionProgress
        anchors.bottomMargin: anchors.topMargin
        clip: true

        IslandContentHost {
            id: contentHost
            anchors.centerIn: parent
            width: Math.max(parent.width, root.expandedWidth
                - 2 * (Design.wing + Design.expandedContentPadding))
            height: Math.max(parent.height, root.expandedHeight
                - 2 * Design.expandedContentPadding)
            module: root.presentedModule
            presented: !root.hidden
            expanded: root.expanded
            expansionProgress: root.expansionProgress
            returningToClock: root.returningToClock
            screenName: root.screenName
        }

        ClockReturnLayer {
            anchors.fill: parent
            visible: root.returningToClock && !root.hidden
            progress: 1 - root.expansionProgress
        }
    }
}
