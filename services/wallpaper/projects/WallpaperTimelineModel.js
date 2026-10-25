.pragma library

var maximumProjectDurationMs = 604800000

function finiteNumber(value, fallback) {
    const numeric = Number(value)
    return Number.isFinite(numeric) ? numeric : fallback
}

function boundedInteger(value, minimum, maximum, fallback) {
    return Math.round(Math.max(minimum, Math.min(maximum,
        finiteNumber(value, fallback))))
}

function trackAcceptsAsset(trackType, assetKind) {
    if (trackType === "media")
        return ["static", "animated-image", "video"].indexOf(assetKind) >= 0
    if (trackType === "audio")
        return assetKind === "audio"
    return false
}

function normalizeTiming(value, sourceDurationMs, projectDurationMs) {
    const source = value || ({})
    const projectLimit = boundedInteger(projectDurationMs, 1,
        maximumProjectDurationMs, maximumProjectDurationMs)
    const startMs = boundedInteger(source.startMs, 0, projectLimit - 1, 0)
    const sourceDuration = boundedInteger(sourceDurationMs, 0,
        maximumProjectDurationMs, 0)
    const sourceInMaximum = sourceDuration > 0 ? sourceDuration - 1
        : maximumProjectDurationMs
    const sourceInMs = boundedInteger(source.sourceInMs, 0,
        sourceInMaximum, 0)
    const projectRemaining = Math.max(1, projectLimit - startMs)
    const sourceRemaining = sourceDuration > 0
        ? Math.max(1, sourceDuration - sourceInMs) : projectRemaining
    const loop = source.loop === true
    const maximumDuration = loop ? projectRemaining
        : Math.min(projectRemaining, sourceRemaining)

    return {
        startMs: startMs,
        durationMs: boundedInteger(source.durationMs, 1,
            maximumDuration, maximumDuration),
        sourceInMs: sourceInMs,
        sourceDurationMs: sourceDuration,
        loop: loop
    }
}

function endMs(timing) {
    return timing.startMs + timing.durationMs
}

function sourceTimeAt(timing, projectTimeMs) {
    const normalized = normalizeTiming(timing, timing?.sourceDurationMs,
        maximumProjectDurationMs)
    const localMs = boundedInteger(projectTimeMs, normalized.startMs,
        endMs(normalized), normalized.startMs) - normalized.startMs
    const availableSourceMs = normalized.sourceDurationMs > 0
        ? Math.max(1, normalized.sourceDurationMs - normalized.sourceInMs)
        : normalized.durationMs
    const offsetMs = normalized.loop
        ? localMs % availableSourceMs
        : Math.min(localMs, availableSourceMs)
    return normalized.sourceInMs + offsetMs
}

function resizeEnd(timing, requestedEndMs, projectDurationMs) {
    const normalized = normalizeTiming(timing, timing?.sourceDurationMs,
        projectDurationMs)
    return normalizeTiming(Object.assign({}, normalized, {
        durationMs: finiteNumber(requestedEndMs, endMs(normalized))
            - normalized.startMs
    }), normalized.sourceDurationMs, projectDurationMs)
}

function trimStart(timing, requestedStartMs, projectDurationMs) {
    const normalized = normalizeTiming(timing, timing?.sourceDurationMs,
        projectDurationMs)
    const nextStart = boundedInteger(requestedStartMs, normalized.startMs,
        endMs(normalized) - 1, normalized.startMs)
    const deltaMs = nextStart - normalized.startMs
    const nextSourceIn = sourceTimeAt(normalized, nextStart)
    return normalizeTiming(Object.assign({}, normalized, {
        startMs: nextStart,
        durationMs: normalized.durationMs - deltaMs,
        sourceInMs: nextSourceIn
    }), normalized.sourceDurationMs, projectDurationMs)
}

function planDrop(track, asset, requestedStartMs, sourceDurationMs,
        projectDurationMs, clipId) {
    if (!track || !asset)
        return { accepted: false, error: "Track and asset are required" }
    if (track.enabled === false || track.locked === true)
        return { accepted: false, error: "Track is not editable" }
    if (!trackAcceptsAsset(track.type, asset.kind))
        return { accepted: false, error: "Asset is incompatible with track" }
    const id = String(clipId || "").trim()
    if (id.length === 0)
        return { accepted: false, error: "A stable clip id is required" }
    const sourceDuration = boundedInteger(sourceDurationMs, 0,
        maximumProjectDurationMs, 0)
    const defaultDuration = sourceDuration > 0 ? sourceDuration : 5000
    const timing = normalizeTiming({
        startMs: requestedStartMs,
        durationMs: defaultDuration,
        sourceInMs: 0,
        loop: false
    }, sourceDuration, projectDurationMs)
    return {
        accepted: true,
        error: "",
        clip: {
            id: id,
            assetId: asset.id,
            startMs: timing.startMs,
            durationMs: timing.durationMs,
            sourceInMs: timing.sourceInMs,
            loop: false,
            enabled: true
        }
    }
}
