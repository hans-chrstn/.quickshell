pragma Singleton

import QtQuick
import Quickshell
import qs.core
import qs.services
import "NotificationModel.js" as NotificationModel

Singleton {
    id: root

    property var queue: []
    property int sequence: 0
    property bool presentationVisible: false
    property var presentedScreens: ({})
    readonly property bool viewPresented:
        Object.keys(presentedScreens).length > 0
    property bool hovered: false
    property double expiresAtMs: 0
    property int remainingDurationMs: 0
    readonly property var current: queue.length > 0 ? queue[0] : null
    readonly property bool hasPresentation: current !== null
    signal closureRequested(string noticeId, string reason)

    function submit(request) {
        sequence += 1
        const source = Object.assign({}, request || ({}))
        source.screenName = ScreenService.resolve(source.screenName || "")
        const result = NotificationModel.enqueue(queue, source,
            Date.now(), sequence)
        if (!result.accepted) return ""
        const becomesCurrent = result.queue[0]?.id === result.notice.id
        queue = result.queue
        if (!presentationVisible) {
            closeTimer.stop()
            presentationVisible = true
        }
        if (becomesCurrent && viewPresented && !hovered) beginExpiry(true)
        return result.notice.id
    }

    function notify(request) {
        return submit(request).length > 0
    }

    function update(noticeId, request) {
        const index = queue.findIndex(item => item.id === noticeId)
        if (index < 0) return false
        sequence += 1
        const previous = queue[index]
        const source = Object.assign({}, request || ({}))
        source.screenName = previous.screenName
        const updated = NotificationModel.normalize(source, Date.now(), sequence)
        if (!updated) return false
        updated.id = previous.id
        updated.createdAtMs = previous.createdAtMs
        updated.occurrenceCount = previous.occurrenceCount
        const next = queue.slice()
        next[index] = updated
        queue = next
        if (index === 0 && presentationVisible && viewPresented && !hovered)
            beginExpiry(true)
        return true
    }

    function showError(title, message, screenName, dedupeKey, source) {
        return notify({ severity: "error", title: title, message: message,
            screenName: screenName, dedupeKey: dedupeKey, source: source })
    }

    function showWarning(title, message, screenName, dedupeKey, source) {
        return notify({ severity: "warning", title: title, message: message,
            screenName: screenName, dedupeKey: dedupeKey, source: source })
    }

    function showSuccess(title, message, screenName, dedupeKey, source) {
        return notify({ severity: "success", title: title, message: message,
            screenName: screenName, dedupeKey: dedupeKey, source: source })
    }

    function setPresented(screenName, value) {
        const key = String(screenName || "view")
        const next = Boolean(value)
        if (next === Boolean(presentedScreens[key])) return
        const updated = Object.assign({}, presentedScreens)
        if (next) updated[key] = true
        else delete updated[key]
        presentedScreens = updated
        if (!viewPresented) {
            pauseExpiry()
            hovered = false
            return
        }
        if (current && presentationVisible && !hovered)
            beginExpiry(false)
    }

    function beginExpiry(resetDeadline) {
        if (!current || !presentationVisible || !viewPresented || hovered)
            return
        const now = Date.now()
        if (resetDeadline || remainingDurationMs <= 0)
            remainingDurationMs = Math.max(NotificationModel.minimumDurationMs,
                Number(current.durationMs) || 4200)
        expiresAtMs = now + remainingDurationMs
        const remaining = Math.round(expiresAtMs - now)
        if (remaining <= 0) {
            dismiss()
            return
        }
        expiryTimer.interval = remaining
        expiryTimer.restart()
    }

    function pauseExpiry() {
        if (expiryTimer.running && expiresAtMs > 0)
            remainingDurationMs = Math.max(1,
                Math.round(expiresAtMs - Date.now()))
        expiryTimer.stop()
        expiresAtMs = 0
    }

    function dismiss(reason) {
        if (!current || !presentationVisible) return
        const closingId = current.id
        expiryTimer.stop()
        expiresAtMs = 0
        remainingDurationMs = 0
        presentationVisible = false
        closeTimer.restart()
        closureRequested(closingId,
            reason === "expired" ? "expired" : "dismissed")
    }

    function remove(noticeId) {
        const index = queue.findIndex(item => item.id === noticeId)
        if (index < 0) return false
        if (index === 0) {
            expiryTimer.stop()
            expiresAtMs = 0
            remainingDurationMs = 0
            presentationVisible = false
            closeTimer.restart()
        } else {
            const next = queue.slice()
            next.splice(index, 1)
            queue = next
        }
        return true
    }

    function setHovered(value) {
        const next = Boolean(value)
        if (next === hovered) return
        hovered = next
        if (!current || !presentationVisible || !viewPresented) return
        if (hovered) pauseExpiry()
        else beginExpiry(false)
    }

    function advance() {
        if (queue.length === 0) return
        queue = queue.slice(1)
        if (current) {
            presentationVisible = true
            expiresAtMs = 0
            remainingDurationMs = 0
            if (viewPresented && !hovered) beginExpiry(true)
        }
    }

    function clear() {
        for (const notice of queue)
            closureRequested(notice.id, "dismissed")
        expiryTimer.stop()
        closeTimer.stop()
        queue = []
        presentationVisible = false
        presentedScreens = ({})
        hovered = false
        expiresAtMs = 0
        remainingDurationMs = 0
    }

    function snapshot() {
        return {
            queueLength: queue.length,
            maximumQueueLength: NotificationModel.maximumQueueLength,
            visible: presentationVisible,
            viewPresented: viewPresented,
            hovered: hovered,
            expiresAtMs: expiresAtMs,
            remainingDurationMs: remainingDurationMs,
            current: current ? Object.assign({}, current) : null
        }
    }

    Timer {
        id: expiryTimer
        onTriggered: root.dismiss("expired")
    }

    Timer {
        id: closeTimer
        interval: Design.moduleHandoffDuration
        onTriggered: root.advance()
    }
}
