.pragma library
.import "WallpaperProjectModel.js" as ProjectModel

var trackTypes = ["media", "transition", "trigger", "audio"]

function failure(message) {
    return { accepted: false, error: message, document: null }
}

function success(document) {
    return { accepted: true, error: "", document: document }
}

function projectOf(document) {
    return document && document.project && Array.isArray(document.project.tracks)
        ? document.project : null
}

function trackIndex(project, trackId) {
    return project.tracks.findIndex(track => track.id === trackId)
}

function copyWithTracks(document, tracks) {
    return Object.assign({}, document, {
        project: Object.assign({}, document.project, { tracks: tracks })
    })
}

function normalizedName(value) {
    return String(value || "").trim().slice(0, 160)
}

function addTrack(document, trackId, name, type, requestedIndex) {
    const project = projectOf(document)
    if (!project) return failure("Canonical project is required")
    if (project.tracks.length >= ProjectModel.maximumTracks)
        return failure("Track limit exceeded")
    const stableId = String(trackId || "").trim()
    if (stableId.length === 0) return failure("A stable track id is required")
    if (trackIndex(project, stableId) >= 0)
        return failure("Track id already exists")
    if (trackTypes.indexOf(type) < 0)
        return failure("Unsupported track type")
    const label = normalizedName(name)
    if (label.length === 0) return failure("Track name is required")
    const index = Math.max(0, Math.min(project.tracks.length,
        Math.round(Number.isFinite(Number(requestedIndex))
            ? Number(requestedIndex) : project.tracks.length)))
    const tracks = project.tracks.slice()
    tracks.splice(index, 0, {
        id: stableId,
        name: label,
        type: type,
        enabled: true,
        locked: false,
        clips: []
    })
    return success(copyWithTracks(document, tracks))
}

function removalReview(document, trackId) {
    const project = projectOf(document)
    const track = project?.tracks.find(value => value.id === trackId)
    if (!track) return null
    return {
        projectId: project.id,
        trackId: track.id,
        name: track.name,
        clipCount: (track.clips || []).length,
        signature: JSON.stringify(track)
    }
}

function removeTrack(document, trackId, review) {
    const project = projectOf(document)
    if (!project) return failure("Canonical project is required")
    const index = trackIndex(project, trackId)
    if (index < 0) return failure("Timeline track was not found")
    const current = removalReview(document, trackId)
    if (review && (review.projectId !== current.projectId
            || review.trackId !== current.trackId
            || review.signature !== current.signature))
        return failure("The track changed. Review it again before removing it")
    if (current.clipCount > 0 && !review)
        return failure("Confirm removal of this track and its clips")
    const tracks = project.tracks.slice()
    tracks.splice(index, 1)
    return success(copyWithTracks(document, tracks))
}

function updateTrack(document, trackId, changes) {
    const project = projectOf(document)
    if (!project) return failure("Canonical project is required")
    const index = trackIndex(project, trackId)
    if (index < 0) return failure("Timeline track was not found")
    const current = project.tracks[index]
    const next = Object.assign({}, current)
    if (changes && changes.name !== undefined) {
        const name = normalizedName(changes.name)
        if (name.length === 0) return failure("Track name is required")
        next.name = name
    }
    if (changes && changes.enabled !== undefined)
        next.enabled = changes.enabled === true
    if (changes && changes.locked !== undefined)
        next.locked = changes.locked === true
    const tracks = project.tracks.slice()
    tracks[index] = next
    return success(copyWithTracks(document, tracks))
}

function reorderTrack(document, trackId, requestedIndex) {
    const project = projectOf(document)
    if (!project) return failure("Canonical project is required")
    const fromIndex = trackIndex(project, trackId)
    if (fromIndex < 0) return failure("Timeline track was not found")
    if (!Number.isFinite(Number(requestedIndex)))
        return failure("Track position is invalid")
    const toIndex = Math.max(0, Math.min(project.tracks.length - 1,
        Math.round(Number(requestedIndex))))
    if (fromIndex === toIndex) return success(document)
    const tracks = project.tracks.slice()
    const moved = tracks.splice(fromIndex, 1)[0]
    tracks.splice(toIndex, 0, moved)
    return success(copyWithTracks(document, tracks))
}
