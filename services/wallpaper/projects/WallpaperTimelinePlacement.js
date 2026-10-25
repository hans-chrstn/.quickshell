.pragma library

function finiteNumber(value, fallback) {
    const numeric = Number(value)
    return Number.isFinite(numeric) ? numeric : fallback
}

function interval(value) {
    const clip = value || ({})
    const startMs = Math.max(0, Math.round(finiteNumber(clip.startMs, 0)))
    const durationMs = Math.max(1,
        Math.round(finiteNumber(clip.durationMs, 1)))
    return { startMs: startMs, endMs: startMs + durationMs }
}

function overlaps(left, right) {
    const a = interval(left)
    const b = interval(right)
    return a.startMs < b.endMs && b.startMs < a.endMs
}

function trackAllowsOverlap(trackType) {
    return trackType === "transition"
}

function validatePlacement(track, candidate, ignoredClipId) {
    if (!track || !Array.isArray(track.clips))
        return { accepted: false, error: "Timeline track is invalid",
            conflictingClipId: "" }
    if (trackAllowsOverlap(track.type))
        return { accepted: true, error: "", conflictingClipId: "" }
    const ignored = String(ignoredClipId || "")
    const conflict = track.clips.find(clip => clip.id !== ignored
        && overlaps(clip, candidate))
    return conflict ? {
        accepted: false,
        error: "Clip overlaps another clip on this track",
        conflictingClipId: conflict.id
    } : { accepted: true, error: "", conflictingClipId: "" }
}

function snapCandidates(tracks, projectDurationMs, ignoredClipId) {
    const values = [0, Math.max(0,
        Math.round(finiteNumber(projectDurationMs, 0)))]
    const ignored = String(ignoredClipId || "")
    for (const track of Array.isArray(tracks) ? tracks : []) {
        for (const clip of Array.isArray(track?.clips) ? track.clips : []) {
            if (clip.id === ignored) continue
            const bounds = interval(clip)
            values.push(bounds.startMs, bounds.endMs)
        }
    }
    return values.filter((value, index) => values.indexOf(value) === index)
        .sort((left, right) => left - right)
}

function snapTime(requestedMs, candidates, toleranceMs) {
    const requested = Math.max(0,
        Math.round(finiteNumber(requestedMs, 0)))
    const tolerance = Math.max(0,
        Math.round(finiteNumber(toleranceMs, 0)))
    let best = requested
    let distance = tolerance + 1
    for (const candidateValue of Array.isArray(candidates) ? candidates : []) {
        const candidate = Math.max(0,
            Math.round(finiteNumber(candidateValue, requested)))
        const candidateDistance = Math.abs(candidate - requested)
        if (candidateDistance < distance
                || (candidateDistance === distance && candidate < best)) {
            best = candidate
            distance = candidateDistance
        }
    }
    return {
        snapped: distance <= tolerance,
        requestedMs: requested,
        timeMs: distance <= tolerance ? best : requested,
        deltaMs: distance <= tolerance ? best - requested : 0
    }
}
