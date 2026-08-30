pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    property var screens: ({})

    function report(screenName, path, state, error, kind, details) {
        const name = String(screenName || "").trim()
        if (name.length === 0)
            return

        const updated = ({})
        for (const key in screens)
            updated[key] = screens[key]
        const previous = screens[name] || ({})
        const now = Date.now()
        const wasActive = Boolean(previous.playbackActive)
        const isActive = Boolean(details?.playbackActive)
        let activeDurationMs = Number(previous.activeDurationMs) || 0
        let activeSinceMs = Number(previous.activeSinceMs) || 0
        if (wasActive && !isActive && activeSinceMs > 0)
            activeDurationMs += Math.max(0, now - activeSinceMs)
        if (!wasActive && isActive)
            activeSinceMs = now
        else if (!isActive)
            activeSinceMs = 0

        updated[name] = {
            path: String(path || ""),
            kind: String(kind || "unknown"),
            state: String(state || "empty"),
            error: String(error || ""),
            suspended: Boolean(details?.suspended),
            suspendedReason: String(details?.suspendedReason || ""),
            suspendedPositionMs: Number(details?.suspendedPositionMs) || 0,
            decoderEvicted: Boolean(details?.decoderEvicted),
            decoderLoaded: Boolean(details?.decoderLoaded),
            playbackActive: isActive,
            activeDurationMs: activeDurationMs,
            activeSinceMs: activeSinceMs
        }
        screens = updated
    }

    function remove(screenName) {
        const name = String(screenName || "").trim()
        const updated = ({})
        for (const key in screens) {
            if (key !== name)
                updated[key] = screens[key]
        }
        screens = updated
    }

    function snapshot() {
        return Object.assign({}, screens)
    }

    function activeDuration(screenName, nowMs) {
        const record = screens[String(screenName || "")] || ({})
        let duration = Number(record.activeDurationMs) || 0
        const since = Number(record.activeSinceMs) || 0
        if (record.playbackActive && since > 0)
            duration += Math.max(0, Number(nowMs) - since)
        return duration
    }
}
