.pragma library

function clipsForTrack(track) {
    return (Array.isArray(track?.clips) ? track.clips : []).slice()
        .sort((left, right) => left.startMs - right.startMs
            || left.id.localeCompare(right.id))
}

function entries(tracks) {
    const result = []
    for (let trackIndex = 0;
            trackIndex < (Array.isArray(tracks) ? tracks.length : 0);
            ++trackIndex) {
        const track = tracks[trackIndex]
        for (const clip of clipsForTrack(track)) {
            result.push({ trackId: track.id, trackIndex: trackIndex,
                clipId: clip.id, clip: clip })
        }
    }
    return result
}

function empty(trackId) {
    return { trackId: String(trackId || ""), primaryClipId: "",
        anchorClipId: "", clipIds: [] }
}

function normalize(state, tracks) {
    const source = state || empty("")
    const ordered = entries(tracks)
    const valid = ({})
    for (const entry of ordered) valid[entry.clipId] = entry
    const requested = Array.isArray(source.clipIds) ? source.clipIds : []
    const requestedSet = ({})
    for (const id of requested) {
        if (valid[id]) requestedSet[id] = true
    }
    const clipIds = ordered.filter(entry => requestedSet[entry.clipId])
        .map(entry => entry.clipId)
    const primaryClipId = valid[source.primaryClipId]
        && requestedSet[source.primaryClipId] ? source.primaryClipId
        : clipIds[0] || ""
    const anchorClipId = valid[source.anchorClipId]
        && requestedSet[source.anchorClipId] ? source.anchorClipId
        : primaryClipId
    const primary = valid[primaryClipId]
    return {
        trackId: primary?.trackId || (Array.isArray(tracks)
            && tracks.some(track => track.id === source.trackId)
            ? source.trackId : ""),
        primaryClipId: primaryClipId,
        anchorClipId: anchorClipId,
        clipIds: clipIds
    }
}

function selectTrack(state, tracks, trackId) {
    if (!(Array.isArray(tracks)
            && tracks.some(track => track.id === trackId)))
        return normalize(state, tracks)
    return empty(trackId)
}

function selectClip(state, tracks, trackId, clipId, mode) {
    const ordered = entries(tracks)
    const target = ordered.find(entry => entry.trackId === trackId
        && entry.clipId === clipId)
    if (!target) return normalize(state, tracks)
    const current = normalize(state, tracks)
    const selectionMode = ["add", "toggle", "range"].indexOf(mode) >= 0
        ? mode : "replace"
    if (selectionMode === "replace")
        return { trackId: trackId, primaryClipId: clipId,
            anchorClipId: clipId, clipIds: [clipId] }
    if (selectionMode === "range") {
        const track = tracks[target.trackIndex]
        const trackClips = clipsForTrack(track)
        const anchorIndex = trackClips.findIndex(clip =>
            clip.id === current.anchorClipId)
        const targetIndex = trackClips.findIndex(clip => clip.id === clipId)
        if (anchorIndex < 0)
            return { trackId: trackId, primaryClipId: clipId,
                anchorClipId: clipId, clipIds: [clipId] }
        const first = Math.min(anchorIndex, targetIndex)
        const last = Math.max(anchorIndex, targetIndex)
        return { trackId: trackId, primaryClipId: clipId,
            anchorClipId: current.anchorClipId,
            clipIds: trackClips.slice(first, last + 1).map(clip => clip.id) }
    }
    const selected = current.clipIds.indexOf(clipId) >= 0
    let clipIds = current.clipIds.slice()
    if (selectionMode === "toggle" && selected)
        clipIds = clipIds.filter(id => id !== clipId)
    else if (!selected)
        clipIds.push(clipId)
    return normalize({ trackId: trackId,
        primaryClipId: clipIds.indexOf(clipId) >= 0 ? clipId
            : current.primaryClipId,
        anchorClipId: clipIds.indexOf(clipId) >= 0 ? clipId
            : current.anchorClipId,
        clipIds: clipIds }, tracks)
}

function focusHorizontal(state, tracks, direction, extend) {
    const current = normalize(state, tracks)
    const track = (Array.isArray(tracks) ? tracks : [])
        .find(value => value.id === current.trackId)
    const clips = clipsForTrack(track)
    if (clips.length === 0) return current
    const currentIndex = clips.findIndex(clip =>
        clip.id === current.primaryClipId)
    const step = direction < 0 ? -1 : 1
    const nextIndex = Math.max(0, Math.min(clips.length - 1,
        currentIndex < 0 ? (step < 0 ? clips.length - 1 : 0)
            : currentIndex + step))
    return selectClip(current, tracks, track.id, clips[nextIndex].id,
        extend === true ? "range" : "replace")
}

function focusVertical(state, tracks, direction) {
    const current = normalize(state, tracks)
    const orderedTracks = Array.isArray(tracks) ? tracks : []
    const fromIndex = orderedTracks.findIndex(track =>
        track.id === current.trackId)
    if (fromIndex < 0 || current.primaryClipId.length === 0) return current
    const currentEntry = entries(orderedTracks).find(entry =>
        entry.clipId === current.primaryClipId)
    const step = direction < 0 ? -1 : 1
    for (let index = fromIndex + step; index >= 0
            && index < orderedTracks.length; index += step) {
        const candidates = clipsForTrack(orderedTracks[index])
        if (candidates.length === 0) continue
        candidates.sort((left, right) =>
            Math.abs(left.startMs - currentEntry.clip.startMs)
            - Math.abs(right.startMs - currentEntry.clip.startMs)
            || left.startMs - right.startMs || left.id.localeCompare(right.id))
        return selectClip(current, tracks, orderedTracks[index].id,
            candidates[0].id, "replace")
    }
    return current
}

function command(state, tracks, action, options) {
    const current = normalize(state, tracks)
    if (current.clipIds.length === 0)
        return { accepted: false, error: "No timeline clips are selected",
            command: null }
    if (["remove", "duplicate"].indexOf(action) >= 0)
        return { accepted: true, error: "", command: {
            type: action + "-clips", clipIds: current.clipIds.slice()
        } }
    if (action === "nudge") {
        const deltaMs = Math.round(Number(options?.deltaMs))
        if (!Number.isFinite(deltaMs) || deltaMs === 0)
            return { accepted: false, error: "Nudge distance is invalid",
                command: null }
        return { accepted: true, error: "", command: {
            type: "nudge-clips", clipIds: current.clipIds.slice(),
            deltaMs: deltaMs
        } }
    }
    if (action === "split") {
        const timeMs = Math.round(Number(options?.timeMs))
        if (!Number.isFinite(timeMs))
            return { accepted: false, error: "Split time is invalid",
                command: null }
        return { accepted: true, error: "", command: {
            type: "split-clips", clipIds: current.clipIds.slice(),
            timeMs: timeMs
        } }
    }
    return { accepted: false, error: "Timeline action is unsupported",
        command: null }
}
