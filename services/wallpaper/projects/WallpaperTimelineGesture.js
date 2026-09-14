.pragma library
.import "WallpaperTimelineModel.js" as Timeline
.import "WallpaperTimelinePlacement.js" as Placement

var modes = ["move", "trim-start", "resize-end"]

function failure(message) {
    return { accepted: false, error: message, gesture: null }
}

function finiteNumber(value, fallback) {
    const numeric = Number(value)
    return Number.isFinite(numeric) ? numeric : fallback
}

function begin(options) {
    const source = options || ({})
    if (modes.indexOf(source.mode) < 0)
        return failure("Unsupported timeline gesture")
    if (!source.clip || String(source.clip.id || "").length === 0)
        return failure("A stable clip is required")
    if (source.mode === "move"
            && String(source.trackId || "").length === 0)
        return failure("A target track is required")
    const gestureId = String(source.gestureId || "").trim()
    if (gestureId.length === 0)
        return failure("A stable gesture id is required")
    const pixelsPerSecond = finiteNumber(source.pixelsPerSecond, 0)
    if (pixelsPerSecond <= 0)
        return failure("Timeline scale must be positive")
    const projectDurationMs = Math.max(1,
        Math.round(finiteNumber(source.projectDurationMs, 0)))
    const timing = Timeline.normalizeTiming(source.clip,
        source.sourceDurationMs, projectDurationMs)
    return {
        accepted: true,
        error: "",
        gesture: {
            id: gestureId,
            mode: source.mode,
            clipId: source.clip.id,
            trackId: String(source.trackId || ""),
            pointerStartX: finiteNumber(source.pointerStartX, 0),
            pixelsPerSecond: pixelsPerSecond,
            snapTolerancePx: Math.max(0,
                finiteNumber(source.snapTolerancePx, 0)),
            projectDurationMs: projectDurationMs,
            sourceDurationMs: Math.max(0,
                Math.round(finiteNumber(source.sourceDurationMs, 0))),
            original: timing
        }
    }
}

function deltaMs(gesture, pointerX) {
    return Math.round((finiteNumber(pointerX, gesture.pointerStartX)
        - gesture.pointerStartX) * 1000 / gesture.pixelsPerSecond)
}

function snapToleranceMs(gesture) {
    return Math.round(gesture.snapTolerancePx * 1000
        / gesture.pixelsPerSecond)
}

function snapMovedStart(gesture, requestedStartMs, candidates) {
    const tolerance = snapToleranceMs(gesture)
    const startSnap = Placement.snapTime(requestedStartMs, candidates,
        tolerance)
    const requestedEndMs = requestedStartMs + gesture.original.durationMs
    const endSnap = Placement.snapTime(requestedEndMs, candidates, tolerance)
    if (!startSnap.snapped && !endSnap.snapped)
        return { snapped: false, timeMs: requestedStartMs, deltaMs: 0 }
    if (startSnap.snapped && (!endSnap.snapped
            || Math.abs(startSnap.deltaMs) <= Math.abs(endSnap.deltaMs)))
        return startSnap
    return {
        snapped: true,
        requestedMs: requestedStartMs,
        timeMs: requestedStartMs + endSnap.deltaMs,
        deltaMs: endSnap.deltaMs
    }
}

function preview(gesture, pointerX, snapCandidates, snappingEnabled) {
    if (!gesture || modes.indexOf(gesture.mode) < 0)
        return { accepted: false, error: "Timeline gesture is invalid",
            preview: null }
    const movementMs = deltaMs(gesture, pointerX)
    let timing = gesture.original
    let snap = { snapped: false, deltaMs: 0 }
    if (gesture.mode === "move") {
        const maximumStart = Math.max(0, gesture.projectDurationMs
            - gesture.original.durationMs)
        let startMs = Math.max(0, Math.min(maximumStart,
            gesture.original.startMs + movementMs))
        if (snappingEnabled !== false) {
            snap = snapMovedStart(gesture, startMs, snapCandidates)
            startMs = Math.max(0, Math.min(maximumStart, snap.timeMs))
        }
        timing = Object.assign({}, gesture.original, { startMs: startMs })
    } else if (gesture.mode === "trim-start") {
        let startMs = gesture.original.startMs + movementMs
        if (snappingEnabled !== false) {
            snap = Placement.snapTime(startMs, snapCandidates,
                snapToleranceMs(gesture))
            startMs = snap.timeMs
        }
        timing = Timeline.trimStart(gesture.original, startMs,
            gesture.projectDurationMs)
    } else {
        let endMs = Timeline.endMs(gesture.original) + movementMs
        if (snappingEnabled !== false) {
            snap = Placement.snapTime(endMs, snapCandidates,
                snapToleranceMs(gesture))
            endMs = snap.timeMs
        }
        timing = Timeline.resizeEnd(gesture.original, endMs,
            gesture.projectDurationMs)
    }
    return {
        accepted: true,
        error: "",
        preview: {
            gestureId: gesture.id,
            mode: gesture.mode,
            clipId: gesture.clipId,
            trackId: gesture.trackId,
            timing: timing,
            snapped: snap.snapped === true,
            snapDeltaMs: snap.snapped === true ? snap.deltaMs : 0
        }
    }
}

function finish(gesture, previewValue) {
    const value = previewValue?.preview || previewValue
    if (!gesture || !value || value.gestureId !== gesture.id
            || value.clipId !== gesture.clipId
            || value.mode !== gesture.mode)
        return { accepted: false, error: "Gesture preview does not match",
            command: null }
    const timing = value.timing
    let command = null
    if (gesture.mode === "move") {
        command = { type: "move-clip", clipId: gesture.clipId,
            trackId: gesture.trackId, startMs: timing.startMs }
    } else if (gesture.mode === "trim-start") {
        command = { type: "trim-clip-start", clipId: gesture.clipId,
            startMs: timing.startMs,
            sourceDurationMs: gesture.sourceDurationMs }
    } else {
        command = { type: "resize-clip-end", clipId: gesture.clipId,
            endMs: Timeline.endMs(timing),
            sourceDurationMs: gesture.sourceDurationMs,
            loop: timing.loop }
    }
    return { accepted: true, error: "", command: command }
}
