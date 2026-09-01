import QtQuick

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
        Qt.callLater(applyTarget)
    }

    function cancelPending() {
        if (pendingIndex >= 0 && pendingIndex !== currentIndex)
            slotFor(pendingIndex).clear()
        pendingIndex = -1
    }

    function applyTarget() {
        updateScheduled = false
        handoffGeneration += 1
        if (failedPath !== targetPath || failedBackend !== targetBackend) {
            failedPath = ""
            failedBackend = ""
            handoffError = ""
        }
        if (!targetSupported) {
            cancelPending()
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
        if (outgoingIndex >= 0 && outgoingIndex !== currentIndex) {
            const outgoing = slotFor(outgoingIndex)
            Qt.callLater(() => {
                if (currentIndex !== outgoingIndex)
                    outgoing.clear()
            })
        }
    }

    function handleSlotState(slot) {
        if (!slot || pendingSlot !== slot || slot.state !== "error")
            return
        failedPath = targetPath
        failedBackend = targetBackend
        handoffError = slot.error.length > 0
            ? slot.error : "Wallpaper renderer failed before handoff"
        const failedIndex = pendingIndex
        pendingIndex = -1
        Qt.callLater(() => {
            if (currentIndex !== failedIndex)
                slot.clear()
        })
    }

    onTargetPathChanged: scheduleTarget()
    onTargetMediaChanged: scheduleTarget()
    onTargetBackendChanged: scheduleTarget()
    onTargetPosterPathChanged: scheduleTarget()
    onRenderScaleChanged: scheduleTarget()

    WallpaperRendererSlot {
        id: slotA
        slotKey: "A"
        anchors.fill: parent
        z: root.pendingIndex === 0 ? 2 : root.currentIndex === 0 ? 1 : 0
        visible: root.pendingIndex === 0 || root.currentIndex === 0
        onVisualReadyChanged: root.tryPromote(slotA)
        onStateChanged: root.handleSlotState(slotA)
    }

    WallpaperRendererSlot {
        id: slotB
        slotKey: "B"
        anchors.fill: parent
        z: root.pendingIndex === 1 ? 2 : root.currentIndex === 1 ? 1 : 0
        visible: root.pendingIndex === 1 || root.currentIndex === 1
        onVisualReadyChanged: root.tryPromote(slotB)
        onStateChanged: root.handleSlotState(slotB)
    }

    Component.onCompleted: scheduleTarget()
}
