.pragma library

var maximumPositionMs = 604800000

function number(value, fallback) {
    const parsed = Number(value)
    return Number.isFinite(parsed) ? parsed : fallback
}

function request(generation, path, positionMs) {
    const position = Math.max(0, Math.min(maximumPositionMs,
        Math.round(number(positionMs, 0))))
    return {
        generation: Math.max(0, Math.round(number(generation, 0))),
        path: String(path || ""),
        positionMs: position,
        valid: String(path || "").length > 0
    }
}

function completionIsCurrent(requested, completed) {
    if (!requested || !completed)
        return false
    return requested.valid === true
        && completed.generation === requested.generation
        && String(completed.path || "") === requested.path
        && Math.round(number(completed.positionMs, -1))
            === requested.positionMs
}

function nextGeneration(current) {
    return Math.max(0, Math.round(number(current, 0))) + 1
}
