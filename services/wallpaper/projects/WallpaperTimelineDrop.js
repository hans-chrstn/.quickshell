.pragma library
.import "WallpaperTimelineEdit.js" as TimelineEdit
.import "WallpaperTimelineModel.js" as TimelineModel
.import "WallpaperTimelineTrackEdit.js" as TrackEdit

function failure(message) {
    return { accepted: false, error: message, document: null,
        trackId: "", clipId: "" }
}

function assetById(document, assetId) {
    return (document?.project?.assets || [])
        .find(asset => asset.id === assetId) || null
}

function compatibleTrack(document, asset, requestedTrackId) {
    const tracks = document?.project?.tracks || []
    if (String(requestedTrackId || "").length > 0)
        return tracks.find(track => track.id === requestedTrackId) || null
    return tracks.find(track => track.enabled !== false
        && track.locked !== true
        && TimelineModel.trackAcceptsAsset(track.type, asset.kind)) || null
}

function plan(document, request) {
    const source = request || ({})
    const assetId = String(source.assetId || "")
    const asset = assetById(document, assetId)
    if (!asset)
        return failure("Project asset was not found")

    const clipId = String(source.clipId || "").trim()
    if (clipId.length === 0)
        return failure("A stable clip id is required")

    const requestedStartMs = Math.max(0,
        Math.round(Number(source.startMs) || 0))
    const sourceDurationMs = asset.kind === "static" ? 0 : Math.max(0,
        Math.round(Number(source.sourceDurationMs) || 0))
    const defaultDurationMs = sourceDurationMs > 0 ? sourceDurationMs : 5000
    const requiredDurationMs = Math.min(
        TimelineModel.maximumProjectDurationMs,
        Math.max(1, requestedStartMs + defaultDurationMs))
    let prepared = Object.assign({}, document, {
        project: Object.assign({}, document.project, {
            durationMs: Math.max(document.project.durationMs || 0,
                requiredDurationMs)
        })
    })

    let track = compatibleTrack(prepared, asset, source.trackId)
    if (String(source.trackId || "").length > 0 && !track)
        return failure("Timeline track was not found")
    if (track && !TimelineModel.trackAcceptsAsset(track.type, asset.kind))
        return failure("Asset is incompatible with track")

    if (!track) {
        const trackId = String(source.newTrackId || "").trim()
        if (trackId.length === 0)
            return failure("A stable track id is required")
        const trackType = asset.kind === "audio" ? "audio" : "media"
        const added = TrackEdit.addTrack(prepared, trackId,
            trackType === "audio" ? "Audio" : "Media", trackType,
            prepared.project.tracks.length)
        if (!added.accepted)
            return failure(added.error)
        prepared = added.document
        track = prepared.project.tracks.find(value => value.id === trackId)
    }

    const inserted = TimelineEdit.insertClip(prepared, track.id, assetId,
        requestedStartMs, sourceDurationMs, clipId)
    if (!inserted.accepted)
        return failure(inserted.error)
    return {
        accepted: true,
        error: "",
        document: inserted.document,
        trackId: track.id,
        clipId: clipId
    }
}
