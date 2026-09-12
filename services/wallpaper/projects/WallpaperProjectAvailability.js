.pragma library

.import "WallpaperProjectModel.js" as ProjectModel

function portableCandidate(rootPath, portablePath) {
    const root = ProjectModel.normalizedSourcePath(rootPath)
        .replace(/\/+$/, "")
    const relative = ProjectModel.normalizedPortablePath(portablePath)
    return root.length > 0 && relative.length > 0
        ? root + "/" + relative : ""
}

function candidates(asset, rootPath) {
    const result = []
    const source = ProjectModel.normalizedSourcePath(asset?.sourcePath)
    const portable = portableCandidate(rootPath, asset?.portablePath)
    if (source.length > 0) result.push(source)
    if (portable.length > 0 && portable !== source) result.push(portable)
    return result
}

function probeRecord(records, path) {
    return records?.[path] || { state: "unknown", kind: "unsupported", error: "" }
}

function resolvedKind(record) {
    return record.kind === "animatedImage" ? "animated-image"
        : String(record.kind || "unknown")
}

function mediaSnapshot(record, path) {
    return {
        path: path,
        state: String(record?.state || "unknown"),
        kind: String(record?.kind || "unsupported"),
        codec: String(record?.codec || ""),
        width: Number(record?.width || 0),
        height: Number(record?.height || 0),
        durationMs: Number(record?.durationMs || 0),
        frameRate: Number(record?.frameRate || 0),
        error: String(record?.error || "")
    }
}

function resolveAsset(asset, rootPath, records) {
    const paths = candidates(asset, rootPath)
    const pending = []
    let unsupported = null
    let failure = null
    for (const path of paths) {
        const record = probeRecord(records, path)
        if (record.state === "ready") {
            return {
                assetId: asset.id,
                state: "available",
                resolvedPath: path,
                resolvedKind: resolvedKind(record),
                media: mediaSnapshot(record, path),
                relinkSuggested: path !== asset.sourcePath,
                candidates: paths,
                enqueuePaths: [],
                error: ""
            }
        }
        if (["unknown", "queued", "probing"].indexOf(record.state) >= 0)
            pending.push(path)
        else if (record.state === "unsupported")
            unsupported = record
        else if (record.state === "failed")
            failure = record
    }
    if (pending.length > 0) {
        return {
            assetId: asset.id, state: "pending", resolvedPath: "",
            resolvedKind: "unknown", relinkSuggested: false,
            media: null,
            candidates: paths, enqueuePaths: pending, error: ""
        }
    }
    const result = unsupported || failure
    return {
        assetId: asset.id,
        state: unsupported ? "unsupported" : "missing",
        resolvedPath: "",
        resolvedKind: "unknown",
        media: null,
        relinkSuggested: false,
        candidates: paths,
        enqueuePaths: [],
        error: String(result?.error || (paths.length === 0
            ? "Asset has no resolvable source path"
            : "Wallpaper source is unavailable"))
    }
}

function plan(document, records) {
    const parsed = ProjectModel.parse(document)
    if (!parsed.accepted)
        return { state: "failed", error: parsed.error, projectId: "",
            complete: true, assets: [], enqueuePaths: [], counts: ({}) }
    const project = parsed.document.project
    const assets = project.assets.map(asset =>
        resolveAsset(asset, project.rootPath, records))
    const enqueuePaths = []
    for (const asset of assets) {
        for (const path of asset.enqueuePaths)
            if (enqueuePaths.indexOf(path) < 0) enqueuePaths.push(path)
    }
    const counts = { available: 0, pending: 0, missing: 0, unsupported: 0 }
    for (const asset of assets) counts[asset.state] += 1
    return {
        state: counts.pending > 0 ? "resolving" : "ready",
        error: "",
        projectId: project.id,
        complete: counts.pending === 0,
        assets: assets,
        enqueuePaths: enqueuePaths,
        counts: counts
    }
}
