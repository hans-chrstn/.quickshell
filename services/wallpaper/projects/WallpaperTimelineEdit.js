.pragma library
.import "WallpaperTimelineModel.js" as Timeline
.import "WallpaperTimelinePlacement.js" as Placement

function failure(message) {
    return { accepted: false, error: message, document: null }
}

function success(document) {
    return { accepted: true, error: "", document: document }
}

function projectOf(document) {
    return document && document.project && Array.isArray(document.project.tracks)
        && Array.isArray(document.project.assets) ? document.project : null
}

function copyWithTracks(document, tracks) {
    return Object.assign({}, document, {
        project: Object.assign({}, document.project, { tracks: tracks })
    })
}

function copiedTrack(track, clips) {
    return Object.assign({}, track, { clips: clips })
}

function assetById(project, assetId) {
    return project.assets.find(asset => asset.id === assetId) || null
}

function trackIndexById(project, trackId) {
    return project.tracks.findIndex(track => track.id === trackId)
}

function locateClip(project, clipId) {
    for (let trackIndex = 0; trackIndex < project.tracks.length; ++trackIndex) {
        const clips = project.tracks[trackIndex].clips || []
        const clipIndex = clips.findIndex(clip => clip.id === clipId)
        if (clipIndex >= 0)
            return { trackIndex: trackIndex, clipIndex: clipIndex,
                clip: clips[clipIndex] }
    }
    return null
}

function clipIdExists(project, clipId) {
    return locateClip(project, clipId) !== null
}

function insertClip(document, trackId, assetId, requestedStartMs,
        sourceDurationMs, clipId) {
    const project = projectOf(document)
    if (!project) return failure("Canonical project is required")
    const trackIndex = trackIndexById(project, trackId)
    if (trackIndex < 0) return failure("Timeline track was not found")
    const asset = assetById(project, assetId)
    if (!asset) return failure("Project asset was not found")
    if (clipIdExists(project, String(clipId || "").trim()))
        return failure("Clip id already exists")
    const plan = Timeline.planDrop(project.tracks[trackIndex], asset,
        requestedStartMs, sourceDurationMs, project.durationMs, clipId)
    if (!plan.accepted) return failure(plan.error)
    const placement = Placement.validatePlacement(project.tracks[trackIndex],
        plan.clip, "")
    if (!placement.accepted) return failure(placement.error)
    const tracks = project.tracks.slice()
    const clips = (tracks[trackIndex].clips || []).slice()
    clips.push(plan.clip)
    clips.sort((left, right) => left.startMs - right.startMs
        || left.id.localeCompare(right.id))
    tracks[trackIndex] = copiedTrack(tracks[trackIndex], clips)
    return success(copyWithTracks(document, tracks))
}

function moveClip(document, clipId, targetTrackId, requestedStartMs) {
    const project = projectOf(document)
    if (!project) return failure("Canonical project is required")
    const location = locateClip(project, clipId)
    if (!location) return failure("Timeline clip was not found")
    const sourceTrack = project.tracks[location.trackIndex]
    if (sourceTrack.enabled === false || sourceTrack.locked === true)
        return failure("Source track is not editable")
    const targetIndex = trackIndexById(project, targetTrackId)
    if (targetIndex < 0) return failure("Target track was not found")
    const target = project.tracks[targetIndex]
    const asset = assetById(project, location.clip.assetId)
    if (!asset || !Timeline.trackAcceptsAsset(target.type, asset.kind))
        return failure("Clip is incompatible with target track")
    if (target.enabled === false || target.locked === true)
        return failure("Target track is not editable")
    const timing = Timeline.normalizeTiming(Object.assign({}, location.clip, {
        startMs: requestedStartMs
    }), location.clip.sourceDurationMs || 0, project.durationMs)
    const moved = Object.assign({}, location.clip, {
        startMs: timing.startMs,
        durationMs: timing.durationMs,
        sourceInMs: timing.sourceInMs
    })
    const placement = Placement.validatePlacement(target, moved, clipId)
    if (!placement.accepted) return failure(placement.error)
    const tracks = project.tracks.map((track, index) => {
        let clips = (track.clips || []).filter(clip => clip.id !== clipId)
        if (index === targetIndex) clips = clips.concat([moved])
        clips.sort((left, right) => left.startMs - right.startMs
            || left.id.localeCompare(right.id))
        return copiedTrack(track, clips)
    })
    return success(copyWithTracks(document, tracks))
}

function resizeClipEnd(document, clipId, requestedEndMs, sourceDurationMs,
        loop) {
    return replaceTiming(document, clipId, sourceDurationMs, timing =>
        Timeline.resizeEnd(Object.assign({}, timing, { loop: loop === true }),
            requestedEndMs, document.project.durationMs))
}

function trimClipStart(document, clipId, requestedStartMs, sourceDurationMs) {
    return replaceTiming(document, clipId, sourceDurationMs, timing =>
        Timeline.trimStart(timing, requestedStartMs,
            document.project.durationMs))
}

function replaceTiming(document, clipId, sourceDurationMs, transform) {
    const project = projectOf(document)
    if (!project) return failure("Canonical project is required")
    const location = locateClip(project, clipId)
    if (!location) return failure("Timeline clip was not found")
    const track = project.tracks[location.trackIndex]
    if (track.enabled === false || track.locked === true)
        return failure("Track is not editable")
    const timing = transform(Object.assign({}, location.clip, {
        sourceDurationMs: sourceDurationMs
    }))
    const replacement = Object.assign({}, location.clip, {
        startMs: timing.startMs,
        durationMs: timing.durationMs,
        sourceInMs: timing.sourceInMs,
        loop: timing.loop
    })
    const placement = Placement.validatePlacement(track, replacement, clipId)
    if (!placement.accepted) return failure(placement.error)
    const tracks = project.tracks.slice()
    const clips = (track.clips || []).slice()
    clips[location.clipIndex] = replacement
    clips.sort((left, right) => left.startMs - right.startMs
        || left.id.localeCompare(right.id))
    tracks[location.trackIndex] = copiedTrack(track, clips)
    return success(copyWithTracks(document, tracks))
}

function removeClip(document, clipId) {
    const project = projectOf(document)
    if (!project) return failure("Canonical project is required")
    const location = locateClip(project, clipId)
    if (!location) return failure("Timeline clip was not found")
    const track = project.tracks[location.trackIndex]
    if (track.enabled === false || track.locked === true)
        return failure("Track is not editable")
    const tracks = project.tracks.slice()
    tracks[location.trackIndex] = copiedTrack(track,
        (track.clips || []).filter(clip => clip.id !== clipId))
    return success(copyWithTracks(document, tracks))
}

function duplicateClip(document, clipId, newClipId, requestedStartMs,
        sourceDurationMs) {
    const project = projectOf(document)
    if (!project) return failure("Canonical project is required")
    const location = locateClip(project, clipId)
    if (!location) return failure("Timeline clip was not found")
    const stableId = String(newClipId || "").trim()
    if (stableId.length === 0) return failure("A stable clip id is required")
    if (clipIdExists(project, stableId)) return failure("Clip id already exists")
    const track = project.tracks[location.trackIndex]
    if (track.enabled === false || track.locked === true)
        return failure("Track is not editable")
    const timing = Timeline.normalizeTiming(Object.assign({}, location.clip, {
        startMs: requestedStartMs
    }), sourceDurationMs, project.durationMs)
    const duplicate = Object.assign({}, location.clip, {
        id: stableId,
        startMs: timing.startMs,
        durationMs: timing.durationMs,
        sourceInMs: timing.sourceInMs,
        loop: timing.loop
    })
    const placement = Placement.validatePlacement(track, duplicate, "")
    if (!placement.accepted) return failure(placement.error)
    const tracks = project.tracks.slice()
    const clips = (track.clips || []).concat([duplicate])
    clips.sort((left, right) => left.startMs - right.startMs
        || left.id.localeCompare(right.id))
    tracks[location.trackIndex] = copiedTrack(track, clips)
    return success(copyWithTracks(document, tracks))
}

function splitClip(document, clipId, splitTimeMs, rightClipId,
        sourceDurationMs) {
    const project = projectOf(document)
    if (!project) return failure("Canonical project is required")
    const location = locateClip(project, clipId)
    if (!location) return failure("Timeline clip was not found")
    const track = project.tracks[location.trackIndex]
    if (track.enabled === false || track.locked === true)
        return failure("Track is not editable")
    if (location.clip.loop === true)
        return failure("Looped clips require an explicit loop-segment split")
    const stableId = String(rightClipId || "").trim()
    if (stableId.length === 0) return failure("A stable clip id is required")
    if (clipIdExists(project, stableId)) return failure("Clip id already exists")
    const startMs = location.clip.startMs
    const endMs = startMs + location.clip.durationMs
    const splitMs = Math.round(Number(splitTimeMs))
    if (!Number.isFinite(splitMs) || splitMs <= startMs || splitMs >= endMs)
        return failure("Split point must be inside the clip")
    const left = Object.assign({}, location.clip, {
        durationMs: splitMs - startMs
    })
    const right = Object.assign({}, location.clip, {
        id: stableId,
        startMs: splitMs,
        durationMs: endMs - splitMs,
        sourceInMs: location.clip.sourceInMs + splitMs - startMs
    })
    const normalizedRight = Timeline.normalizeTiming(right, sourceDurationMs,
        project.durationMs)
    right.durationMs = normalizedRight.durationMs
    right.sourceInMs = normalizedRight.sourceInMs
    const tracks = project.tracks.slice()
    const clips = (track.clips || []).slice()
    clips.splice(location.clipIndex, 1, left, right)
    tracks[location.trackIndex] = copiedTrack(track, clips)
    return success(copyWithTracks(document, tracks))
}
