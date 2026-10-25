.pragma library
.import "WallpaperTimelineViewport.js" as Viewport

var intervalsMs = [10, 20, 50, 100, 200, 500, 1000, 2000, 5000,
    10000, 15000, 30000, 60000, 120000, 300000, 600000, 900000,
    1800000, 3600000, 7200000, 21600000, 43200000, 86400000]

function finiteNumber(value, fallback) {
    const numeric = Number(value)
    return Number.isFinite(numeric) ? numeric : fallback
}

function firstIntervalAtLeast(requiredMs) {
    for (const interval of intervalsMs) {
        if (interval >= requiredMs) return interval
    }
    return intervalsMs[intervalsMs.length - 1]
}

function majorMultiple(required) {
    const multipliers = [1, 2, 5, 10, 20, 50, 100]
    for (const multiplier of multipliers) {
        if (multiplier >= required) return multiplier
    }
    return Math.ceil(required / 100) * 100
}

function policy(viewport, minimumTickSpacingPx, minimumLabelSpacingPx,
        maximumTicks) {
    const state = Viewport.normalize(viewport)
    const tickSpacing = Math.max(4, finiteNumber(minimumTickSpacingPx, 12))
    const labelSpacing = Math.max(tickSpacing,
        finiteNumber(minimumLabelSpacingPx, 64))
    const tickLimit = Math.max(16,
        Math.round(finiteNumber(maximumTicks, 512)))
    const visible = Viewport.visibleRange(state, 0)
    const visibleDurationMs = Math.max(1, visible.endMs - visible.startMs)
    const spacingRequiredMs = tickSpacing * 1000 / state.pixelsPerSecond
    const countRequiredMs = visibleDurationMs / tickLimit
    const minorIntervalMs = firstIntervalAtLeast(Math.max(
        spacingRequiredMs, countRequiredMs))
    const labelRequiredMs = labelSpacing * 1000 / state.pixelsPerSecond
    const majorIntervalMs = minorIntervalMs * majorMultiple(
        labelRequiredMs / minorIntervalMs)
    return {
        minorIntervalMs: minorIntervalMs,
        majorIntervalMs: majorIntervalMs,
        minorSpacingPx: minorIntervalMs * state.pixelsPerSecond / 1000,
        majorSpacingPx: majorIntervalMs * state.pixelsPerSecond / 1000,
        maximumTicks: tickLimit
    }
}

function pad(value, width) {
    return String(value).padStart(width, "0")
}

function label(timeMs, majorIntervalMs) {
    const totalMs = Math.max(0, Math.round(finiteNumber(timeMs, 0)))
    const interval = Math.max(1,
        Math.round(finiteNumber(majorIntervalMs, 1000)))
    if (interval < 1000)
        return (totalMs / 1000).toFixed(interval < 100 ? 2 : 1) + "s"
    const totalSeconds = Math.floor(totalMs / 1000)
    const seconds = totalSeconds % 60
    const totalMinutes = Math.floor(totalSeconds / 60)
    const minutes = totalMinutes % 60
    const totalHours = Math.floor(totalMinutes / 60)
    if (totalHours < 1)
        return totalMinutes + ":" + pad(seconds, 2)
    if (totalHours < 24)
        return totalHours + ":" + pad(minutes, 2)
            + ":" + pad(seconds, 2)
    const days = Math.floor(totalHours / 24)
    return days + "d " + pad(totalHours % 24, 2)
        + ":" + pad(minutes, 2) + ":" + pad(seconds, 2)
}

function ticks(viewport, overscanPx, minimumTickSpacingPx,
        minimumLabelSpacingPx, maximumTicks) {
    const state = Viewport.normalize(viewport)
    const tickPolicy = policy(state, minimumTickSpacingPx,
        minimumLabelSpacingPx, maximumTicks)
    const range = Viewport.visibleRange(state,
        Math.max(0, finiteNumber(overscanPx, 0)))
    const firstMs = Math.ceil(range.startMs
        / tickPolicy.minorIntervalMs) * tickPolicy.minorIntervalMs
    const result = []
    for (let timeMs = firstMs; timeMs <= range.endMs
            && result.length < tickPolicy.maximumTicks;
            timeMs += tickPolicy.minorIntervalMs) {
        const major = timeMs % tickPolicy.majorIntervalMs === 0
        result.push({
            timeMs: timeMs,
            x: Viewport.timeToViewportX(state, timeMs),
            major: major,
            label: major ? label(timeMs, tickPolicy.majorIntervalMs) : ""
        })
    }
    return { policy: tickPolicy, ticks: result, range: range }
}

function playhead(viewport, timeMs) {
    const state = Viewport.normalize(viewport)
    const boundedTimeMs = Math.max(0, Math.min(state.durationMs,
        Math.round(finiteNumber(timeMs, 0))))
    const x = Viewport.timeToViewportX(state, boundedTimeMs)
    return {
        timeMs: boundedTimeMs,
        x: x,
        visible: x >= 0 && x <= state.viewportWidth
    }
}
