.pragma library
.import "WallpaperTimelineEdit.js" as Edit
.import "WallpaperTimelinePlacement.js" as Placement

function failure(message) {
    return { accepted: false, error: message, document: null,
        changedClipIds: [] }
}

function success(document, changedClipIds) {
    return { accepted: true, error: "", document: document,
        changedClipIds: changedClipIds.slice() }
}

function projectOf(document) {
    return document && document.project && Array.isArray(document.project.tracks)
        ? document.project : null
}

function uniqueIds(value) {
    const result = []
    const seen = ({})
    for (const idValue of Array.isArray(value) ? value : []) {
        const id = String(idValue || "").trim()
        if (id.length > 0 && !seen[id]) {
            seen[id] = true
            result.push(id)
        }
    }
    return result
}

function locations(project) {
    const result = ({})
    for (let trackIndex = 0; trackIndex < project.tracks.length; ++trackIndex) {
        const track = project.tracks[trackIndex]
        for (let clipIndex = 0; clipIndex < (track.clips || []).length;
                ++clipIndex) {
            const clip = track.clips[clipIndex]
            result[clip.id] = { track: track, trackIndex: trackIndex,
                clip: clip, clipIndex: clipIndex }
        }
    }
    return result
}

function validateSelection(document, clipIds) {
    const project = projectOf(document)
    if (!project) return { accepted: false,
        error: "Canonical project is required" }
    const ids = uniqueIds(clipIds)
    if (ids.length === 0)
        return { accepted: false, error: "No timeline clips are selected" }
    const byId = locations(project)
    for (const id of ids) {
        const location = byId[id]
        if (!location)
            return { accepted: false, error: "Timeline clip was not found: " + id }
        if (location.track.enabled === false || location.track.locked === true)
            return { accepted: false, error: "Track is not editable: "
                + location.track.id }
    }
    return { accepted: true, error: "", project: project,
        clipIds: ids, byId: byId }
}

function remove(document, selection) {
    const selected = ({})
    for (const id of selection.clipIds) selected[id] = true
    const tracks = selection.project.tracks.map(track => Object.assign({}, track, {
        clips: (track.clips || []).filter(clip => !selected[clip.id])
    }))
    return success(Object.assign({}, document, {
        project: Object.assign({}, document.project, { tracks: tracks })
    }), selection.clipIds)
}

function validateTrackPlacements(track) {
    const clips = track.clips || []
    for (let index = 0; index < clips.length; ++index) {
        const placement = Placement.validatePlacement(track, clips[index],
            clips[index].id)
        if (!placement.accepted) return placement
    }
    return { accepted: true, error: "" }
}

function nudge(document, selection, deltaMs) {
    const delta = Math.round(Number(deltaMs))
    if (!Number.isFinite(delta) || delta === 0)
        return failure("Nudge distance is invalid")
    const selected = ({})
    for (const id of selection.clipIds) selected[id] = true
    const durationMs = Math.max(1,
        Math.round(Number(selection.project.durationMs) || 1))
    const tracks = selection.project.tracks.map(track => Object.assign({}, track, {
        clips: (track.clips || []).map(clip => {
            if (!selected[clip.id]) return clip
            const startMs = clip.startMs + delta
            if (startMs < 0 || startMs + clip.durationMs > durationMs)
                return null
            return Object.assign({}, clip, { startMs: startMs })
        })
    }))
    if (tracks.some(track => track.clips.some(clip => clip === null)))
        return failure("Nudge would move a clip outside the project")
    for (const track of tracks) {
        const placement = validateTrackPlacements(track)
        if (!placement.accepted) return failure(placement.error)
        track.clips.sort((left, right) => left.startMs - right.startMs
            || left.id.localeCompare(right.id))
    }
    return success(Object.assign({}, document, {
        project: Object.assign({}, document.project, { tracks: tracks })
    }), selection.clipIds)
}

function mappingValue(mapping, clipId) {
    return mapping && typeof mapping === "object"
        ? String(mapping[clipId] || "").trim() : ""
}

function duplicate(document, selection, command) {
    let current = document
    const created = []
    for (const clipId of selection.clipIds) {
        const newId = mappingValue(command.newClipIds, clipId)
        const requestedStart = Number(command.startMsByClipId?.[clipId])
        const sourceDuration = Number(command.sourceDurationMsByClipId?.[clipId])
        if (newId.length === 0 || !Number.isFinite(requestedStart))
            return failure("Duplicate identity and placement are required")
        const result = Edit.duplicateClip(current, clipId, newId,
            requestedStart, Number.isFinite(sourceDuration) ? sourceDuration : 0)
        if (!result.accepted) return failure(result.error)
        current = result.document
        created.push(newId)
    }
    return success(current, created)
}

function split(document, selection, command) {
    const timeMs = Math.round(Number(command.timeMs))
    if (!Number.isFinite(timeMs)) return failure("Split time is invalid")
    let current = document
    const created = []
    for (const clipId of selection.clipIds) {
        const newId = mappingValue(command.newClipIds, clipId)
        const sourceDuration = Number(command.sourceDurationMsByClipId?.[clipId])
        if (newId.length === 0)
            return failure("Split identity is required")
        const result = Edit.splitClip(current, clipId, timeMs, newId,
            Number.isFinite(sourceDuration) ? sourceDuration : 0)
        if (!result.accepted) return failure(result.error)
        current = result.document
        created.push(newId)
    }
    return success(current, created)
}

function apply(document, command) {
    if (!command || typeof command !== "object")
        return failure("Timeline command is required")
    const selection = validateSelection(document, command.clipIds)
    if (!selection.accepted) return failure(selection.error)
    if (command.type === "remove-clips")
        return remove(document, selection)
    if (command.type === "nudge-clips")
        return nudge(document, selection, command.deltaMs)
    if (command.type === "duplicate-clips")
        return duplicate(document, selection, command)
    if (command.type === "split-clips")
        return split(document, selection, command)
    return failure("Timeline batch command is unsupported")
}
