import QtQuick
import qs.services.config
import qs.services.wallpaper
import "WallpaperTransitionPolicy.js" as TransitionPolicy

Item {
    id: root

    required property string targetPath
    required property var targetMedia
    required property string targetBackend
    required property string screenName
    property string targetPosterPath: ""
    property real renderScale: 1

    property int handoffGeneration: 0
    property int currentIndex: -1
    property int pendingIndex: -1
    property bool updateScheduled: false
    property string failedPath: ""
    property string failedBackend: ""
    property string handoffError: ""
    property int transitionOutgoingIndex: -1
    property bool pendingRapidSelection: false

    readonly property bool transitionRunning: transition.running
    readonly property real transitionProgress: transition.progress
    readonly property string transitionReason: transitionDecision.reason || ""
    readonly property int retainedRendererCount:
        (slotA.configured ? 1 : 0) + (slotB.configured ? 1 : 0)
    property var transitionDecision: TransitionPolicy.decision({})

    readonly property WallpaperRendererSlot currentSlot:
        currentIndex === 0 ? slotA : currentIndex === 1 ? slotB : null
    readonly property WallpaperRendererSlot pendingSlot:
        pendingIndex === 0 ? slotA : pendingIndex === 1 ? slotB : null
    readonly property bool targetSupported: targetPath.length > 0
        && targetMedia?.state === "ready" && targetBackend.length > 0
    readonly property bool currentMatchesTarget: currentSlot
        && currentSlot.path === targetPath && currentSlot.backend === targetBackend
    readonly property bool targetFailed: failedPath === targetPath
        && failedBackend === targetBackend && handoffError.length > 0
    readonly property string state: targetPath.length === 0 ? "empty"
        : targetMedia?.state === "failed" || targetMedia?.state === "unsupported"
            || targetFailed ? "error"
        : !targetSupported || !currentMatchesTarget
                ? "loading" : currentSlot.state
    readonly property string error: targetMedia?.state === "failed"
            || targetMedia?.state === "unsupported"
        ? String(targetMedia?.error || "Unsupported wallpaper media")
        : targetFailed ? handoffError
        : currentMatchesTarget ? currentSlot.error : ""
    readonly property bool suspended: currentMatchesTarget && currentSlot.suspended
    readonly property string suspendedReason: suspended
        ? currentSlot.suspendedReason : ""
    readonly property int suspendedPositionMs: suspended
        ? currentSlot.suspendedPositionMs : 0
    readonly property bool decoderEvicted:
        currentMatchesTarget && currentSlot.decoderEvicted
    readonly property bool decoderLoaded:
        currentMatchesTarget && currentSlot.decoderLoaded
    readonly property bool playbackActive:
        currentMatchesTarget && currentSlot.playbackActive

    function slotFor(index) { return index === 0 ? slotA : slotB }

    function scheduleTarget() {
        if (updateScheduled)
            return
        updateScheduled = true
        targetUpdateTimer.restart()
    }

    function cancelPending() {
        if (pendingIndex >= 0 && pendingIndex !== currentIndex)
            slotFor(pendingIndex).clear()
        pendingIndex = -1
    }

    function cancelTransition() {
        if (!transition.running && transitionOutgoingIndex < 0)
            return
        transition.cancel()
        const outgoingIndex = transitionOutgoingIndex
        transitionOutgoingIndex = -1
        if (outgoingIndex >= 0 && outgoingIndex !== currentIndex)
            slotFor(outgoingIndex).clear()
    }

    function applyTarget() {
        updateScheduled = false
        handoffGeneration += 1
        pendingRapidSelection = transition.running
        if (transition.running)
            cancelTransition()
        if (failedPath !== targetPath || failedBackend !== targetBackend) {
            failedPath = ""
            failedBackend = ""
            handoffError = ""
        }
        if (!targetSupported) {
            cancelPending()
            if (targetMedia?.state === "failed"
                    || targetMedia?.state === "unsupported") {
                transitionDecision = TransitionPolicy.decision({
                    outgoingPath: currentSlot?.path || "",
                    outgoingBackend: currentSlot?.backend || "",
                    incomingPath: targetPath,
                    incomingBackend: targetBackend.length > 0
                        ? targetBackend : "unsupported",
                    incomingFailed: true
                })
            }
            return
        }
        if (currentMatchesTarget) {
            cancelPending()
            currentSlot.updateContext(targetMedia, targetPosterPath, renderScale)
            return
        }
        const nextIndex = currentIndex === 0 ? 1 : 0
        const slot = slotFor(nextIndex)
        pendingIndex = nextIndex
        slot.configure(handoffGeneration, targetPath, targetMedia,
            targetBackend, screenName, targetPosterPath, renderScale)
        tryPromote(slot)
    }

    function tryPromote(slot) {
        if (!slot || pendingSlot !== slot || !slot.visualReady
                || slot.generation !== handoffGeneration
                || slot.path !== targetPath || slot.backend !== targetBackend)
            return
        const outgoingIndex = currentIndex
        currentIndex = pendingIndex
        pendingIndex = -1
        transitionDecision = TransitionPolicy.decision({
            outgoingPath: outgoingIndex >= 0
                ? slotFor(outgoingIndex).path : "",
            outgoingBackend: outgoingIndex >= 0
                ? slotFor(outgoingIndex).backend : "",
            incomingPath: slot.path,
            incomingBackend: slot.backend,
            presentationVisible:
                !WallpaperOcclusionService.known(screenName)
                || !WallpaperOcclusionService.covered(screenName),
            outgoingSuspended: outgoingIndex >= 0
                && slotFor(outgoingIndex).suspended,
            outgoingEvicted: outgoingIndex >= 0
                && slotFor(outgoingIndex).decoderEvicted,
            incomingSuspended: slot.suspended,
            incomingEvicted: slot.decoderEvicted,
            rapidSelection: pendingRapidSelection,
            enabled: ConfigService.wallpaperTransitionsEnabled,
            reducedMotion: ConfigService.reduceWallpaperMotion,
            durationMs: ConfigService.wallpaperTransitionDuration
        })
        pendingRapidSelection = false
        if (outgoingIndex < 0 || outgoingIndex === currentIndex)
            return
        if (!transitionDecision.enabled) {
            slotFor(outgoingIndex).clear()
            return
        }
        transitionOutgoingIndex = outgoingIndex
        transition.start(handoffGeneration, transitionDecision.durationMs)
    }

    function finishTransition(generation) {
        if (generation !== handoffGeneration)
            return
        const outgoingIndex = transitionOutgoingIndex
        transitionOutgoingIndex = -1
        if (outgoingIndex >= 0 && outgoingIndex !== currentIndex)
            slotFor(outgoingIndex).clear()
    }

    function recordHandoffFailure(slot, fallbackMessage) {
        failedPath = targetPath
        failedBackend = targetBackend
        handoffError = slot.error.length > 0
            ? slot.error : fallbackMessage
        transitionDecision = TransitionPolicy.decision({
            outgoingPath: currentSlot?.path || "",
            outgoingBackend: currentSlot?.backend || "",
            incomingPath: targetPath,
            incomingBackend: targetBackend,
            incomingFailed: true
        })
    }

    function clearFailedSlotLater(slot, failedIndex, failedGeneration) {
        Qt.callLater(() => {
            if (slot.generation === failedGeneration
                    && currentIndex !== failedIndex
                    && pendingIndex !== failedIndex)
                slot.clear()
        })
    }

    function handleSlotState(slot) {
        if (!slot || slot.state !== "error")
            return
        if (pendingSlot === slot) {
            recordHandoffFailure(slot,
                "Wallpaper renderer failed before handoff")
            const failedIndex = pendingIndex
            const failedGeneration = slot.generation
            pendingIndex = -1
            clearFailedSlotLater(slot, failedIndex, failedGeneration)
            return
        }
        if (transition.running && currentSlot === slot
                && transitionOutgoingIndex >= 0) {
            recordHandoffFailure(slot,
                "Wallpaper renderer failed during handoff")
            const failedIndex = currentIndex
            const failedGeneration = slot.generation
            const fallbackIndex = transitionOutgoingIndex
            transition.cancel()
            transitionOutgoingIndex = -1
            currentIndex = fallbackIndex
            clearFailedSlotLater(slot, failedIndex, failedGeneration)
        }
    }

    onTargetPathChanged: scheduleTarget()
    onTargetMediaChanged: scheduleTarget()
    onTargetBackendChanged: scheduleTarget()
    onTargetPosterPathChanged: scheduleTarget()
    onRenderScaleChanged: scheduleTarget()

    Connections {
        target: ConfigService

        function onWallpaperTransitionsEnabledChanged() {
            if (!ConfigService.wallpaperTransitionsEnabled)
                root.cancelTransition()
        }

        function onReduceWallpaperMotionChanged() {
            if (ConfigService.reduceWallpaperMotion)
                root.cancelTransition()
        }
    }

    Timer {
        id: targetUpdateTimer
        interval: 0
        repeat: false
        onTriggered: root.applyTarget()
    }

    WallpaperTransitionController {
        id: transition
        onCompleted: generation => root.finishTransition(generation)
    }

    WallpaperRendererSlot {
        id: slotA
        slotKey: "A"
        anchors.fill: parent
        z: root.currentIndex === 0 ? 2
            : root.transitionOutgoingIndex === 0 ? 1
            : root.pendingIndex === 0 ? 2 : 0
        visible: root.pendingIndex === 0 || root.currentIndex === 0
            || root.transitionOutgoingIndex === 0
        opacity: root.transitionRunning && root.currentIndex === 0
            ? root.transitionProgress : 1
        onVisualReadyChanged: root.tryPromote(slotA)
        onStateChanged: root.handleSlotState(slotA)
    }

    WallpaperRendererSlot {
        id: slotB
        slotKey: "B"
        anchors.fill: parent
        z: root.currentIndex === 1 ? 2
            : root.transitionOutgoingIndex === 1 ? 1
            : root.pendingIndex === 1 ? 2 : 0
        visible: root.pendingIndex === 1 || root.currentIndex === 1
            || root.transitionOutgoingIndex === 1
        opacity: root.transitionRunning && root.currentIndex === 1
            ? root.transitionProgress : 1
        onVisualReadyChanged: root.tryPromote(slotB)
        onStateChanged: root.handleSlotState(slotB)
    }

    Component.onCompleted: scheduleTarget()
}
