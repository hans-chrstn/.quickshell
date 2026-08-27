import QtQuick
import Quickshell
import qs.core
import qs.components
import qs.modules.clock
import qs.modules.launcher
import qs.modules.session

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
    readonly property bool keyboardRequested:
        registry.current?.wantsKeyboard ?? false

    ModuleRegistry {
        id: registry
        modules: [
            ClockModuleSpec { },
            LauncherModuleSpec { screenName: root.screenName },
            SessionModuleSpec { screenName: root.screenName }
        ]
    }

    readonly property int maximumExpandedHeight: {
        let maximum = Design.defaultExpandedHeight
        for (let module of registry.modules)
            maximum = Math.max(maximum, module?.expandedHeight ?? 0)
        return maximum
    }

    Connections {
        target: registry
        function onAttentionRequestedChanged() {
            root.attentionRequested = registry.attentionRequested
            if (root.attentionRequested) {
                hideTimer.stop()
                if (root.expanded) {
                    attentionExpandTimer.stop()
                } else {
                    root.reveal(false)
                    attentionExpandTimer.restart()
                }
            } else {
                attentionExpandTimer.stop()
                expandTimer.stop()
                hideTimer.stop()
                root.presentationState = root.pointerPresent
                    ? root.expandedState : root.collapsedState
                moduleHandoffTimer.restart()
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
        interval: Design.moduleCloseDuration
        onTriggered: root.reconsider()
    }

    readonly property bool hidden: presentationState === hiddenState
    readonly property bool expanded: presentationState === expandedState
    readonly property bool pointerPresent: edgeHovered || islandHover.hovered
    readonly property real expansionProgress: {
        const distance = expandedWidth - collapsedWidth
        if (distance <= 0)
            return expanded ? 1 : 0
        return Math.max(0, Math.min(1, (width - collapsedWidth) / distance))
    }

    property int collapsedWidth: registry.current?.collapsedWidth
        ?? Design.collapsedWidth
    property int collapsedHeight: Design.collapsedHeight
    property int expandedWidth: registry.current?.expandedWidth
        ?? Design.defaultExpandedWidth
    property int expandedHeight: registry.current?.expandedHeight
        ?? Design.defaultExpandedHeight

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
            easing.type: Easing.OutCubic
        }
    }

    Behavior on height {
        NumberAnimation {
            duration: Design.resizeDuration
            easing.type: Easing.OutCubic
        }
    }

    function reveal(expand) {
        hideTimer.stop()
        presentationState = expand ? expandedState : collapsedState
    }

    function requestAttention(duration) {
        attentionRequested = true
        reveal(true)
        attentionTimer.interval = Math.max(500, duration || 2500)
        attentionTimer.restart()
    }

    function reconsider() {
        if (pointerPresent || attentionRequested) {
            hideTimer.stop()
            if (hidden)
                presentationState = collapsedState
            if (pointerPresent)
                expandTimer.restart()
        } else {
            expandTimer.stop()
            presentationState = collapsedState
            hideTimer.restart()
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
            root.attentionRequested = false
            root.reconsider()
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

    HoverHandler { id: islandHover }

    IslandContentHost {
        anchors.fill: parent
        anchors.leftMargin: Design.wing + Design.contentHorizontalPadding
            + (Design.expandedContentPadding - Design.contentHorizontalPadding)
                * root.expansionProgress
        anchors.rightMargin: anchors.leftMargin
        anchors.topMargin: Design.contentVerticalPadding
            + (Design.expandedContentPadding - Design.contentVerticalPadding)
                * root.expansionProgress
        anchors.bottomMargin: anchors.topMargin
        module: registry.current
        expanded: root.expanded
        expansionProgress: root.expansionProgress
        screenName: root.screenName
    }
}
