.pragma library
.import "WallpaperTimelineSelection.js" as TimelineSelection

var selectionKinds = ["none", "asset", "track", "clips", "marker"];

function empty(projectId) {
    return {
        kind: "none",
        projectId: String(projectId || ""),
        assetId: "",
        trackId: "",
        primaryClipId: "",
        anchorClipId: "",
        clipIds: [],
        markerId: ""
    };
}

function projectRecord(document) {
    const project = document?.project;
    return project && typeof project === "object" ? project : null;
}

function timelineState(selection) {
    const source = selection || empty("");
    if (source.kind !== "track" && source.kind !== "clips")
        return TimelineSelection.empty("");
    return {
        trackId: String(source.trackId || ""),
        primaryClipId: String(source.primaryClipId || ""),
        anchorClipId: String(source.anchorClipId || ""),
        clipIds: Array.isArray(source.clipIds) ? source.clipIds.slice() : []
    };
}

function fromTimeline(projectId, state, tracks) {
    const timeline = TimelineSelection.normalize(state, tracks);
    const base = empty(projectId);
    if (timeline.clipIds.length > 0) {
        base.kind = "clips";
        base.trackId = timeline.trackId;
        base.primaryClipId = timeline.primaryClipId;
        base.anchorClipId = timeline.anchorClipId;
        base.clipIds = timeline.clipIds.slice();
    } else if (timeline.trackId.length > 0) {
        base.kind = "track";
        base.trackId = timeline.trackId;
    }
    return base;
}

function normalize(selection, document) {
    const project = projectRecord(document);
    if (!project)
        return empty("");
    const projectId = String(project.id || "");
    const source = selection || empty(projectId);
    if (source.projectId && source.projectId !== projectId)
        return empty(projectId);
    const kind = selectionKinds.indexOf(source.kind) >= 0 ? source.kind : "none";
    if (kind === "asset") {
        const assetId = String(source.assetId || "");
        if ((project.assets || []).some(asset => asset.id === assetId)) {
            const result = empty(projectId);
            result.kind = "asset";
            result.assetId = assetId;
            return result;
        }
    } else if (kind === "marker") {
        const markerId = String(source.markerId || "");
        if ((project.markers || []).some(marker => marker.id === markerId)) {
            const result = empty(projectId);
            result.kind = "marker";
            result.markerId = markerId;
            return result;
        }
    } else if (kind === "track" || kind === "clips") {
        return fromTimeline(projectId, timelineState(source), project.tracks || []);
    }
    return empty(projectId);
}

function selectAsset(document, assetId) {
    const project = projectRecord(document);
    if (!project)
        return empty("");
    return normalize({
        kind: "asset",
        projectId: project.id,
        assetId: String(assetId || "")
    }, document);
}

function selectMarker(selection, document, markerId, toggle) {
    const project = projectRecord(document);
    if (!project)
        return empty("");
    const id = String(markerId || "");
    const current = normalize(selection, document);
    if (toggle === true && current.kind === "marker" && current.markerId === id)
        return empty(project.id);
    return normalize({
        kind: "marker",
        projectId: project.id,
        markerId: id
    }, document);
}

function selectTrack(selection, document, trackId) {
    const project = projectRecord(document);
    if (!project)
        return empty("");
    const timeline = TimelineSelection.selectTrack(timelineState(normalize(selection, document)), project.tracks || [], String(trackId || ""));
    return fromTimeline(project.id, timeline, project.tracks || []);
}

function selectClip(selection, document, trackId, clipId, mode) {
    const project = projectRecord(document);
    if (!project)
        return empty("");
    const timeline = TimelineSelection.selectClip(timelineState(normalize(selection, document)), project.tracks || [], String(trackId || ""), String(clipId || ""), String(mode || "replace"));
    return fromTimeline(project.id, timeline, project.tracks || []);
}

function selectAllClips(document) {
    const project = projectRecord(document);
    if (!project)
        return empty("");
    const tracks = project.tracks || [];
    const entries = TimelineSelection.entries(tracks);
    if (entries.length === 0)
        return empty(project.id);
    return fromTimeline(project.id, {
        trackId: entries[0].trackId,
        primaryClipId: entries[0].clipId,
        anchorClipId: entries[0].clipId,
        clipIds: entries.map(entry => entry.clipId)
    }, tracks);
}
