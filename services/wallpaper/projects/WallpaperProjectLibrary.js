.pragma library

.import "WallpaperProjectModel.js" as ProjectModel

var schemaVersion = 1
var maximumProjects = 64

function parse(value) {
    if (!value || typeof value !== "object" || Array.isArray(value))
        return failure("Project library must be an object")
    const version = Number(value.schemaVersion ?? schemaVersion)
    if (!Number.isFinite(version) || version > schemaVersion)
        return failure("Unsupported future project-library version " + version)
    if (!Array.isArray(value.projects))
        return failure("Project library must contain a projects array")
    if (value.projects.length > maximumProjects)
        return failure("Project limit exceeded")

    const projects = []
    const used = ({})
    for (let index = 0; index < value.projects.length; ++index) {
        const parsed = ProjectModel.parse(value.projects[index])
        if (!parsed.accepted)
            return failure("Project " + (index + 1) + ": " + parsed.error)
        const id = parsed.document.project.id
        if (used[id])
            return failure("Duplicate project id: " + id)
        used[id] = true
        projects.push(parsed.document)
    }
    const requestedActive = String(value.activeProjectId || "").trim()
    return {
        accepted: true,
        error: "",
        document: {
            schemaVersion: schemaVersion,
            activeProjectId: used[requestedActive] ? requestedActive : "",
            projects: projects
        }
    }
}

function failure(message) {
    return { accepted: false, error: String(message || "Invalid project library"),
        document: null }
}

function emptyDocument() {
    return { schemaVersion: schemaVersion, activeProjectId: "", projects: [] }
}

function projectIndex(document, projectId) {
    const id = String(projectId || "")
    return (document?.projects || []).findIndex(
        project => project.project.id === id)
}

function upsert(document, projectDocument) {
    const library = parse(document)
    if (!library.accepted) return library
    const project = ProjectModel.parse(projectDocument)
    if (!project.accepted) return failure(project.error)
    const projects = library.document.projects.slice()
    const index = projectIndex(library.document, project.document.project.id)
    if (index < 0) {
        if (projects.length >= maximumProjects)
            return failure("Project limit exceeded")
        projects.push(project.document)
    } else {
        projects[index] = project.document
    }
    return parse({
        schemaVersion: schemaVersion,
        activeProjectId: library.document.activeProjectId,
        projects: projects
    })
}

function remove(document, projectId) {
    const library = parse(document)
    if (!library.accepted) return library
    const id = String(projectId || "")
    const projects = library.document.projects.filter(
        project => project.project.id !== id)
    if (projects.length === library.document.projects.length)
        return failure("Project not found: " + id)
    return parse({
        schemaVersion: schemaVersion,
        activeProjectId: library.document.activeProjectId === id
            ? "" : library.document.activeProjectId,
        projects: projects
    })
}
