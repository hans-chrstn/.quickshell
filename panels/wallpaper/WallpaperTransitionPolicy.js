.pragma library

var minimumDurationMs = 120
var maximumDurationMs = 800
var defaultDurationMs = 420
var pressuredDurationMs = 180
var maximumRendererSlots = 2

function boundedDuration(value) {
    const number = Math.round(Number(value))
    return Number.isFinite(number)
        ? Math.max(minimumDurationMs, Math.min(maximumDurationMs, number))
        : defaultDurationMs
}

function decision(input) {
    const value = input || ({})
    const outgoingPath = String(value.outgoingPath || "")
    const incomingPath = String(value.incomingPath || "")
    const outgoingBackend = String(value.outgoingBackend || "")
    const incomingBackend = String(value.incomingBackend || "")
    const motionTransition = outgoingBackend !== "static"
        || incomingBackend !== "static"
    const pressure = String(value.resourcePressure || "none")
    const duration = boundedDuration(value.durationMs)

    if (incomingPath.length === 0 || incomingBackend.length === 0)
        return skipped("invalid-incoming")
    if (outgoingPath.length === 0 || outgoingBackend.length === 0)
        return skipped("initial-load")
    if (outgoingPath === incomingPath
            && outgoingBackend === incomingBackend)
        return skipped("same-renderer")
    if (value.incomingFailed === true)
        return skipped("incoming-failed")
    if (value.enabled === false)
        return skipped("disabled")
    if (value.presentationVisible === false && motionTransition)
        return skipped("not-visible")
    if (value.outgoingSuspended === true)
        return skipped("playback-suspended")
    if (value.outgoingEvicted === true)
        return skipped("decoder-evicted")
    if (value.incomingSuspended === true)
        return skipped("playback-suspended")
    if (value.incomingEvicted === true)
        return skipped("decoder-evicted")
    if (value.reducedMotion === true)
        return skipped("reduced-motion")
    if (value.rapidSelection === true)
        return skipped("rapid-selection")
    if (pressure === "high")
        return skipped("resource-pressure")
    if (pressure === "moderate")
        return enabled(Math.min(duration, pressuredDurationMs),
            "resource-pressure-shortened")
    return enabled(duration, "crossfade")
}

function enabled(duration, reason) {
    return {
        enabled: true,
        durationMs: duration,
        outgoingRetentionMs: duration,
        maximumRendererSlots: maximumRendererSlots,
        reason: reason
    }
}

function skipped(reason) {
    return {
        enabled: false,
        durationMs: 0,
        outgoingRetentionMs: 0,
        maximumRendererSlots: maximumRendererSlots,
        reason: reason
    }
}
