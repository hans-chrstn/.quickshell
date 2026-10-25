.pragma library
.import "WallpaperProjectRuntimePlan.js" as RuntimePlan

var maximumDurationMs = 604800000

function number(value, fallback) {
    const parsed = Number(value)
    return Number.isFinite(parsed) ? parsed : fallback
}

function clamp(value, minimum, maximum) {
    return Math.max(minimum, Math.min(maximum, value))
}

function normalize(value) {
    const source = value || ({})
    const durationMs = Math.round(clamp(number(source.durationMs, 0), 0,
        maximumDurationMs))
    const loopStartMs = Math.round(clamp(number(source.loopStartMs, 0), 0,
        durationMs))
    const loopEndMs = Math.round(clamp(number(source.loopEndMs, durationMs),
        loopStartMs, durationMs))
    const positionMs = Math.round(clamp(number(source.positionMs, 0), 0,
        durationMs))
    return {
        durationMs: durationMs,
        positionMs: positionMs,
        playing: source.playing === true && durationMs > 0,
        loopEnabled: source.loopEnabled === true && loopEndMs > loopStartMs,
        loopStartMs: loopStartMs,
        loopEndMs: loopEndMs
    }
}

function play(state) {
    const current = normalize(state)
    return Object.assign({}, current, {
        playing: current.durationMs > 0
            && (current.loopEnabled || current.positionMs < current.durationMs)
    })
}

function pause(state) {
    return Object.assign({}, normalize(state), { playing: false })
}

function seek(state, positionMs) {
    const current = normalize(state)
    const position = Math.round(clamp(number(positionMs, 0), 0,
        current.durationMs))
    return Object.assign({}, current, {
        positionMs: position,
        playing: current.playing && (current.loopEnabled
            || position < current.durationMs)
    })
}

function setLoop(state, enabled, startMs, endMs) {
    const current = normalize(state)
    const start = Math.round(clamp(number(startMs, current.loopStartMs), 0,
        current.durationMs))
    const end = Math.round(clamp(number(endMs, current.loopEndMs), start,
        current.durationMs))
    const valid = end > start
    return Object.assign({}, current, {
        loopEnabled: enabled === true && valid,
        loopStartMs: start,
        loopEndMs: end,
        positionMs: current.positionMs < start || current.positionMs > end
            ? start : current.positionMs
    })
}

function advance(state, elapsedMs) {
    const current = normalize(state)
    const elapsed = Math.max(0, number(elapsedMs, 0))
    if (!current.playing || elapsed === 0)
        return { state: current, reachedEnd: false, wrapped: false }
    const boundary = current.loopEnabled ? current.loopEndMs : current.durationMs
    const origin = Math.min(current.positionMs, boundary)
    const requested = origin + elapsed
    if (requested < boundary)
        return { state: Object.assign({}, current, { positionMs: requested }),
            reachedEnd: false, wrapped: false }
    if (current.loopEnabled) {
        const span = Math.max(1, current.loopEndMs - current.loopStartMs)
        const wrapped = current.loopStartMs + ((requested - current.loopStartMs) % span)
        return { state: Object.assign({}, current, { positionMs: wrapped }),
            reachedEnd: false, wrapped: true }
    }
    return { state: Object.assign({}, current, {
        positionMs: current.durationMs, playing: false
    }), reachedEnd: true, wrapped: false }
}

function frameAt(plan, state, screenName) {
    const current = normalize(state)
    if (!plan || typeof plan !== "object") return []
    return RuntimePlan.frameForScreen(plan, current.positionMs, screenName)
}
