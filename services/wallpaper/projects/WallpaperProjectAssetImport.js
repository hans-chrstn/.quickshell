.pragma library

.import "WallpaperProjectModel.js" as ProjectModel
.import "../WallpaperRenderSupport.js" as RenderSupport

var maximumImportBatch = 64

function basename(path) {
    const value = String(path || "")
    return value.slice(value.lastIndexOf("/") + 1) || "Imported Media"
}

function stem(path) {
    const name = basename(path)
    const dot = name.lastIndexOf(".")
    return dot > 0 ? name.slice(0, dot) : name
}

function nextId(path, requestedId, used) {
    const base = ProjectModel.identifier(requestedId,
        ProjectModel.identifier(stem(path), "asset"))
    let candidate = base
    let suffix = 2
    while (used[candidate]) {
        candidate = (base + "-" + suffix).slice(0, 96)
        suffix += 1
    }
    used[candidate] = true
    return candidate
}

function projectKind(media) {
    if (media?.kind === "animatedImage") return "animated-image"
    if (media?.kind === "video") return "video"
    if (media?.kind === "static") return "static"
    return "unknown"
}

function rejected(path, reason, error) {
    return { path: path, reason: reason, error: String(error || "") }
}

function apply(document, candidates) {
    const parsed = ProjectModel.parse(document)
    if (!parsed.accepted)
        return { accepted: false, error: parsed.error, document: null,
            imported: [], skipped: [] }
    if (!Array.isArray(candidates))
        return { accepted: false, error: "Import candidates must be an array",
            document: null, imported: [], skipped: [] }
    if (candidates.length > maximumImportBatch)
        return { accepted: false, error: "Import batch limit exceeded",
            document: null, imported: [], skipped: [] }

    const project = parsed.document.project
    const existingPaths = ({})
    const usedIds = ({})
    for (const asset of project.assets) {
        if (asset.sourcePath.length > 0) existingPaths[asset.sourcePath] = true
        usedIds[asset.id] = true
    }
    const imported = []
    const skipped = []
    for (const candidate of candidates) {
        const path = ProjectModel.normalizedSourcePath(
            candidate?.sourcePath || candidate?.path)
        const media = candidate?.media || candidate
        if (path.length === 0) {
            skipped.push(rejected(path, "invalid-path", "Absolute path required"))
            continue
        }
        if (existingPaths[path]) {
            skipped.push(rejected(path, "duplicate", "Already in project"))
            continue
        }
        if (media?.state !== "ready") {
            skipped.push(rejected(path, "unavailable",
                media?.error || "Media is unavailable"))
            continue
        }
        if (!RenderSupport.supported(media)) {
            skipped.push(rejected(path, "unsupported",
                media?.error || "No accepted wallpaper renderer"))
            continue
        }
        if (project.assets.length + imported.length
                >= ProjectModel.maximumAssets) {
            skipped.push(rejected(path, "project-limit",
                "Project asset limit reached"))
            continue
        }
        existingPaths[path] = true
        imported.push({
            id: nextId(path, candidate?.assetId || candidate?.id, usedIds),
            name: ProjectModel.text(candidate?.name, 160) || basename(path),
            kind: projectKind(media),
            sourcePath: path,
            portablePath: ProjectModel.normalizedPortablePath(
                candidate?.portablePath),
            availability: "unresolved"
        })
    }
    if (imported.length === 0)
        return { accepted: false, error: skipped.length > 0
                ? "No importable media" : "Import batch is empty",
            document: parsed.document, imported: [], skipped: skipped }
    project.assets = project.assets.concat(imported)
    const normalized = ProjectModel.parse(parsed.document)
    return { accepted: normalized.accepted, error: normalized.error,
        document: normalized.document, imported: imported, skipped: skipped }
}
