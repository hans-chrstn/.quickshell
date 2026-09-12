.pragma library

.import "WallpaperProjectModel.js" as ProjectModel

var schemaVersion = 1
var maximumWorkspaces = 32

function containedRoot(basePath, workspaceId) {
    const base = ProjectModel.normalizedSourcePath(basePath).replace(/\/+$/, "")
    const id = ProjectModel.identifier(workspaceId, "")
    return base.length > 0 && id.length > 0 ? base + "/" + id : ""
}

function normalizeEntry(value, basePath) {
    const source = value || ({})
    const id = ProjectModel.identifier(source.id, "")
    const expected = containedRoot(basePath, id)
    return {
        id: id,
        projectId: ProjectModel.identifier(source.projectId, ""),
        rootPath: expected,
        manifestPath: expected.length > 0 ? expected + "/bundle.json" : "",
        createdAtMs: ProjectModel.integer(source.createdAtMs, 0,
            Number.MAX_SAFE_INTEGER, 0),
        updatedAtMs: ProjectModel.integer(source.updatedAtMs, 0,
            Number.MAX_SAFE_INTEGER, 0)
    }
}

function parse(value, basePath) {
    const errors = []
    if (!value || typeof value !== "object" || Array.isArray(value))
        return { accepted: false, error: "Draft registry must be an object",
            document: null }
    if (Math.floor(Number(value.schemaVersion) || 0) !== schemaVersion)
        errors.push("Unsupported draft registry version")
    if (!Array.isArray(value.workspaces))
        errors.push("Draft registry workspaces must be an array")
    const source = Array.isArray(value.workspaces) ? value.workspaces : []
    if (source.length > maximumWorkspaces)
        errors.push("Draft workspace limit exceeded")
    const ids = ({})
    const projects = ({})
    const workspaces = source.map(entry => normalizeEntry(entry, basePath))
    for (const entry of workspaces) {
        if (entry.id.length === 0) errors.push("Draft workspace id is missing")
        if (entry.projectId.length === 0) errors.push("Draft project id is missing")
        if (ids[entry.id]) errors.push("Duplicate draft workspace id: " + entry.id)
        if (projects[entry.projectId])
            errors.push("Project already has a draft: " + entry.projectId)
        ids[entry.id] = true
        projects[entry.projectId] = true
    }
    return { accepted: errors.length === 0, error: errors.join("; "),
        document: errors.length === 0
            ? { schemaVersion: schemaVersion, workspaces: workspaces } : null }
}

function empty() {
    return { schemaVersion: schemaVersion, workspaces: [] }
}

function upsert(document, entry, basePath) {
    const parsed = parse(document, basePath)
    if (!parsed.accepted) return parsed
    const normalized = normalizeEntry(entry, basePath)
    if (normalized.id.length === 0 || normalized.projectId.length === 0)
        return { accepted: false, error: "Draft identity is incomplete",
            document: null }
    const current = parsed.document.workspaces
    const sameProject = current.find(item => item.projectId === normalized.projectId
        && item.id !== normalized.id)
    if (sameProject)
        return { accepted: false, error: "Project already has a draft: "
            + normalized.projectId, document: null }
    const index = current.findIndex(item => item.id === normalized.id)
    if (index < 0 && current.length >= maximumWorkspaces)
        return { accepted: false, error: "Draft workspace limit reached",
            document: null }
    const next = current.slice()
    if (index >= 0) next[index] = normalized
    else next.push(normalized)
    return parse({ schemaVersion: schemaVersion, workspaces: next }, basePath)
}

function remove(document, workspaceId, basePath) {
    const parsed = parse(document, basePath)
    if (!parsed.accepted) return parsed
    const id = ProjectModel.identifier(workspaceId, "")
    return parse({ schemaVersion: schemaVersion,
        workspaces: parsed.document.workspaces.filter(item => item.id !== id)
    }, basePath)
}
