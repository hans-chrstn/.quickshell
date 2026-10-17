.pragma library

.import "WallpaperProjectModel.js" as ProjectModel
.import "WallpaperProjectBundleModel.js" as Bundle

var maximumFolderNameLength = 128

function failure(message) {
    return { accepted: false, error: String(message || "Invalid save destination"),
        plan: null }
}

function folderName(value) {
    const name = String(value ?? "").trim()
    if (name.length === 0 || name.length > maximumFolderNameLength
            || name === "." || name === ".." || name.startsWith(".")
            || /[\/\\\x00-\x1f\x7f]/.test(name))
        return ""
    return name
}

function parentPath(value) {
    const normalized = ProjectModel.normalizedSourcePath(value)
    if (normalized.length === 0) return ""
    return normalized === "/" ? "/" : normalized.replace(/\/+$/, "")
}

function join(parent, name) {
    return parent === "/" ? "/" + name : parent + "/" + name
}

function create(request, workspace, manifest, nowMs) {
    const source = request || ({})
    const entry = workspace || ({})
    const parsed = Bundle.parse(manifest)
    if (!parsed.accepted) return failure(parsed.error)
    if (parsed.document.workspace.id !== String(entry.id || "")
            || parsed.document.workspace.projectId !== String(entry.projectId || ""))
        return failure("Draft identity does not match")
    const rootPath = ProjectModel.normalizedSourcePath(entry.rootPath)
    if (rootPath.length === 0)
        return failure("Draft workspace root is unavailable")
    const parent = parentPath(source.parentPath)
    const name = folderName(source.folderName)
    if (parent.length === 0)
        return failure("Save parent must be an absolute path")
    if (name.length === 0)
        return failure("Project folder name is invalid")
    const operationId = ProjectModel.identifier(source.operationId, "")
    if (operationId.length === 0)
        return failure("Save operation identity is missing")
    if (parsed.document.workspace.files.some(file => file.state !== "ready"))
        return failure("Bundle contains incomplete files")

    const destinationPath = join(parent, name)
    const saving = Bundle.beginSave(parsed.document, destinationPath, nowMs)
    if (!saving.accepted) return failure(saving.error)
    return { accepted: true, error: "", plan: {
        workspaceId: entry.id,
        projectId: entry.projectId,
        sourceRootPath: rootPath,
        sourceManifestPath: rootPath + "/bundle.json",
        parentPath: parent,
        folderName: name,
        destinationPath: destinationPath,
        stagingPath: join(parent, "." + name + ".saving-" + operationId),
        publicationStrategy: "destination-local-copy-then-rename",
        savingDocument: saving.document
    } }
}
