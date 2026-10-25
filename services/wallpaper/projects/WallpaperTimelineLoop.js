.pragma library

function finite(value, fallback) {
    const result = Number(value)
    return Number.isFinite(result) ? result : fallback
}

function normalize(value) {
    const source = value || ({})
    const durationMs = Math.max(0, Math.round(finite(source.durationMs, 0)))
    const minimumSpanMs = Math.max(1,
        Math.round(finite(source.minimumSpanMs, 1)))
    const startMs = Math.max(0, Math.min(durationMs,
        Math.round(finite(source.startMs, 0))))
    const endMs = Math.max(startMs, Math.min(durationMs,
        Math.round(finite(source.endMs, durationMs))))
    const valid = endMs - startMs >= minimumSpanMs
    return {
        durationMs: durationMs,
        minimumSpanMs: minimumSpanMs,
        startMs: valid ? startMs : Math.max(0, durationMs - minimumSpanMs),
        endMs: valid ? endMs : durationMs,
        enabled: source.enabled === true && valid
    }
}

function setEnabled(value, enabled) {
    const source = value || ({})
    const current = normalize(value)
    const durationMs = Math.max(0, Math.round(finite(source.durationMs, 0)))
    const minimumSpanMs = Math.max(1,
        Math.round(finite(source.minimumSpanMs, 1)))
    const requestedStart = Math.round(finite(source.startMs, 0))
    const requestedEnd = Math.round(finite(source.endMs, durationMs))
    const requestedSpanIsValid = requestedEnd >= requestedStart
        && requestedEnd - requestedStart >= minimumSpanMs
        && requestedStart >= 0 && requestedEnd <= durationMs
    return Object.assign({}, current, {
        enabled: enabled === true && requestedSpanIsValid
            && current.endMs - current.startMs >= current.minimumSpanMs
    })
}

function moveStart(value, requestedMs) {
    const current = normalize(value)
    const maximum = Math.max(current.startMs,
        current.endMs - current.minimumSpanMs)
    return Object.assign({}, current, {
        startMs: Math.max(0, Math.min(maximum,
            Math.round(finite(requestedMs, current.startMs))))
    })
}

function moveEnd(value, requestedMs) {
    const current = normalize(value)
    const minimum = Math.min(current.endMs,
        current.startMs + current.minimumSpanMs)
    return Object.assign({}, current, {
        endMs: Math.min(current.durationMs, Math.max(minimum,
            Math.round(finite(requestedMs, current.endMs))))
    })
}

function contains(value, positionMs) {
    const current = normalize(value)
    const position = Math.round(finite(positionMs, 0))
    return position >= current.startMs && position < current.endMs
}
