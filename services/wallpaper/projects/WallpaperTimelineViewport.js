.pragma library

function finiteNumber(value, fallback) {
    const numeric = Number(value)
    return Number.isFinite(numeric) ? numeric : fallback
}

function clamp(value, minimum, maximum) {
    return Math.max(minimum, Math.min(maximum, value))
}

function normalize(value) {
    const source = value || ({})
    const durationMs = Math.max(1,
        Math.round(finiteNumber(source.durationMs, 1)))
    const viewportWidth = Math.max(1,
        finiteNumber(source.viewportWidth, 1))
    const minimumPixelsPerSecond = Math.max(1,
        finiteNumber(source.minimumPixelsPerSecond, 10))
    const maximumPixelsPerSecond = Math.max(minimumPixelsPerSecond,
        finiteNumber(source.maximumPixelsPerSecond, 2000))
    const pixelsPerSecond = clamp(
        finiteNumber(source.pixelsPerSecond, minimumPixelsPerSecond),
        minimumPixelsPerSecond, maximumPixelsPerSecond)
    const contentWidth = Math.max(viewportWidth,
        durationMs * pixelsPerSecond / 1000)
    const maximumScrollX = Math.max(0, contentWidth - viewportWidth)
    return {
        durationMs: durationMs,
        viewportWidth: viewportWidth,
        minimumPixelsPerSecond: minimumPixelsPerSecond,
        maximumPixelsPerSecond: maximumPixelsPerSecond,
        pixelsPerSecond: pixelsPerSecond,
        contentWidth: contentWidth,
        maximumScrollX: maximumScrollX,
        scrollX: clamp(finiteNumber(source.scrollX, 0), 0, maximumScrollX)
    }
}

function timeToContentX(viewport, timeMs) {
    const state = normalize(viewport)
    return clamp(finiteNumber(timeMs, 0), 0, state.durationMs)
        * state.pixelsPerSecond / 1000
}

function timeToViewportX(viewport, timeMs) {
    const state = normalize(viewport)
    return timeToContentX(state, timeMs) - state.scrollX
}

function contentXToTime(viewport, contentX) {
    const state = normalize(viewport)
    return Math.round(clamp(clamp(finiteNumber(contentX, 0), 0,
        state.contentWidth) * 1000 / state.pixelsPerSecond,
    0, state.durationMs))
}

function viewportXToTime(viewport, viewportX) {
    const state = normalize(viewport)
    return contentXToTime(state, state.scrollX
        + finiteNumber(viewportX, 0))
}

function scrollTo(viewport, requestedScrollX) {
    return normalize(Object.assign({}, viewport, { scrollX: requestedScrollX }))
}

function scrollBy(viewport, deltaX) {
    const state = normalize(viewport)
    return scrollTo(state, state.scrollX + finiteNumber(deltaX, 0))
}

function zoomAround(viewport, requestedPixelsPerSecond, anchorViewportX) {
    const before = normalize(viewport)
    const anchorX = clamp(finiteNumber(anchorViewportX, 0), 0,
        before.viewportWidth)
    const anchorTimeMs = viewportXToTime(before, anchorX)
    const scaled = normalize(Object.assign({}, before, {
        pixelsPerSecond: requestedPixelsPerSecond,
        scrollX: 0
    }))
    const requestedScrollX = timeToContentX(scaled, anchorTimeMs) - anchorX
    return scrollTo(scaled, requestedScrollX)
}

function visibleRange(viewport, overscanPx) {
    const state = normalize(viewport)
    const overscan = Math.max(0, finiteNumber(overscanPx, 0))
    return {
        startMs: contentXToTime(state,
            Math.max(0, state.scrollX - overscan)),
        endMs: contentXToTime(state,
            Math.min(state.contentWidth,
                state.scrollX + state.viewportWidth + overscan))
    }
}

function clipIsVisible(clip, range) {
    const startMs = Math.max(0,
        Math.round(finiteNumber(clip?.startMs, 0)))
    const endMs = startMs + Math.max(1,
        Math.round(finiteNumber(clip?.durationMs, 1)))
    return startMs < range.endMs && range.startMs < endMs
}

function visibleClips(clips, viewport, overscanPx) {
    const range = visibleRange(viewport, overscanPx)
    const source = []
    if (Array.isArray(clips)) {
        for (const clip of clips) source.push(clip)
    } else {
        const length = Math.max(0,
            Math.round(finiteNumber(clips?.length, 0)))
        for (let index = 0; index < length; ++index)
            source.push(clips[index])
    }
    return source.filter(clip => clipIsVisible(clip, range))
}
