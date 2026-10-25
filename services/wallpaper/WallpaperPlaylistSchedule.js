.pragma library

var defaultDurationMs = 300000
var minimumDurationMs = 1000
var maximumDurationMs = 604800000

function duration(value, fallback) {
    const preferred = Number(value)
    if (Number.isFinite(preferred) && preferred > 0)
        return Math.round(Math.max(minimumDurationMs,
            Math.min(maximumDurationMs, preferred)))
    const defaultValue = Number(fallback)
    if (Number.isFinite(defaultValue) && defaultValue > 0)
        return Math.round(Math.max(minimumDurationMs,
            Math.min(maximumDurationMs, defaultValue)))
    return defaultDurationMs
}

function dormant(reason) {
    return {
        state: "dormant",
        reason: String(reason || "unavailable"),
        entryId: "",
        index: -1,
        path: "",
        startedAtMs: 0,
        durationMs: 0,
        nextAtMs: 0,
        advancedSteps: 0,
        cyclesSkipped: 0,
        clockRebased: false
    }
}

function plan(entries, cursor, nowMs, fallbackDurationMs) {
    const ordered = entries || []
    if (ordered.length === 0)
        return dormant("empty-playlist")

    const now = Math.max(0, Math.floor(Number(nowMs) || 0))
    const requestedId = String(cursor?.entryId || "")
    let index = ordered.findIndex(entry => entry.id === requestedId)
    let startedAt = Math.floor(Number(cursor?.startedAtMs) || 0)
    let clockRebased = false
    if (index < 0 || startedAt <= 0) {
        index = 0
        startedAt = now
    } else if (now < startedAt) {
        startedAt = now
        clockRebased = true
    }

    const durations = ordered.map(entry =>
        duration(entry.durationMs, fallbackDurationMs))
    const cycleDuration = durations.reduce((sum, value) => sum + value, 0)
    let elapsed = Math.max(0, now - startedAt)
    let advancedSteps = 0
    let cyclesSkipped = 0

    if (cycleDuration > 0 && elapsed >= cycleDuration) {
        cyclesSkipped = Math.floor(elapsed / cycleDuration)
        elapsed -= cyclesSkipped * cycleDuration
        startedAt += cyclesSkipped * cycleDuration
        advancedSteps += cyclesSkipped * ordered.length
    }

    while (elapsed >= durations[index]) {
        elapsed -= durations[index]
        startedAt += durations[index]
        index = (index + 1) % ordered.length
        advancedSteps += 1
    }

    const entry = ordered[index]
    return {
        state: "ready",
        reason: "",
        entryId: String(entry.id || ""),
        index: index,
        path: String(entry.path || ""),
        startedAtMs: startedAt,
        durationMs: durations[index],
        nextAtMs: startedAt + durations[index],
        advancedSteps: advancedSteps,
        cyclesSkipped: cyclesSkipped,
        clockRebased: clockRebased
    }
}
