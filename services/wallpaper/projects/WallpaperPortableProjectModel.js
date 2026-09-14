.pragma library

.import "WallpaperProjectModel.js" as ProjectModel

var formatId = "new-shell.wallpaper-project"
var schemaVersion = 1

function failure(message) {
    return { accepted: false, error: String(message || "Invalid portable project"),
        document: null }
}

function portableProject(document) {
    const parsed = ProjectModel.parse(document)
    if (!parsed.accepted) return parsed
    const project = parsed.document.project
    project.rootPath = ""
    project.assets = project.assets.map(asset => Object.assign({}, asset, {
        sourcePath: "",
        availability: "unresolved"
    }))
    return ProjectModel.parse(parsed.document)
}

function create(document, savedAtMs) {
    const portable = portableProject(document)
    if (!portable.accepted) return failure(portable.error)
    const project = portable.document.project
    if (project.assets.some(asset => asset.portablePath.length === 0))
        return failure("Every saved asset requires a portable path")
    return { accepted: true, error: "", document: {
        formatId: formatId,
        schemaVersion: schemaVersion,
        projectId: project.id,
        savedAtMs: ProjectModel.integer(savedAtMs, 0,
            Number.MAX_SAFE_INTEGER, 0),
        projectDocument: portable.document
    } }
}

function parse(value) {
    if (!value || typeof value !== "object" || Array.isArray(value))
        return failure("Portable project must be an object")
    if (String(value.formatId || "") !== formatId)
        return failure("Folder is not a New Shell wallpaper project")
    const version = Math.floor(Number(value.schemaVersion) || 0)
    if (version > schemaVersion)
        return failure("Unsupported future portable project version " + version)
    if (version !== schemaVersion)
        return failure("Unsupported portable project version " + version)

    const portable = portableProject(value.projectDocument)
    if (!portable.accepted) return failure(portable.error)
    const project = portable.document.project
    if (String(value.projectId || "") !== project.id)
        return failure("Portable project identity does not match")
    const sourceProject = value.projectDocument?.project || ({})
    if (String(sourceProject.rootPath || "").length > 0
            || ProjectModel.collection(sourceProject.assets).some(asset =>
                String(asset?.sourcePath || asset?.path || "").length > 0))
        return failure("Portable project contains machine-specific paths")
    if (project.assets.some(asset => asset.portablePath.length === 0))
        return failure("Portable project asset path is missing")

    return { accepted: true, error: "", document: {
        formatId: formatId,
        schemaVersion: schemaVersion,
        projectId: project.id,
        savedAtMs: ProjectModel.integer(value.savedAtMs, 0,
            Number.MAX_SAFE_INTEGER, 0),
        projectDocument: portable.document
    } }
}
