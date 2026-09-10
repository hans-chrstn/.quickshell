.pragma library

.import "WallpaperProjectModel.js" as ProjectModel
.import "WallpaperProjectBundleModel.js" as Bundle

var maximumQueue = 64
var maximumFileNameLength = 220

function baseName(path) {
    const value = ProjectModel.normalizedSourcePath(path)
    return value.slice(value.lastIndexOf("/") + 1)
}

function safeFileName(path) {
    const original = baseName(path).replace(/[\x00-\x1f\x7f]/g, "")
    if (original.length === 0 || original === "." || original === "..")
        return "imported-asset"
    if (original.length <= maximumFileNameLength) return original
    const dot = original.lastIndexOf(".")
    const extension = dot > 0 && original.length - dot <= 24
        ? original.slice(dot) : ""
    return original.slice(0, maximumFileNameLength - extension.length)
        + extension
}

function splitName(name) {
    const dot = name.lastIndexOf(".")
    return dot > 0 ? { stem: name.slice(0, dot), extension: name.slice(dot) }
        : { stem: name, extension: "" }
}

function availableRelativePath(role, sourcePath, manifest) {
    const directory = Bundle.roleDirectory(role)
    if (directory.length === 0) return ""
    const used = ({})
    const files = manifest?.workspace?.files
    if (Array.isArray(files))
        for (const file of files) used[String(file.relativePath || "")] = true
    const parts = splitName(safeFileName(sourcePath))
    let suffix = 1
    let relative = directory + "/" + parts.stem + parts.extension
    while (used[relative] && suffix < Bundle.maximumFiles + 2) {
        suffix += 1
        relative = directory + "/" + parts.stem + "-" + suffix
            + parts.extension
    }
    return used[relative] ? "" : relative
}

function create(request, workspace, manifest, usedIds) {
    const source = request || ({})
    const entry = workspace || ({})
    const parsed = Bundle.parse(manifest)
    if (!parsed.accepted)
        return { accepted: false, error: parsed.error, plan: null }
    if (parsed.document.workspace.id !== entry.id
            || parsed.document.workspace.projectId !== entry.projectId)
        return { accepted: false, error: "Draft identity does not match",
            plan: null }
    const sourcePath = ProjectModel.normalizedSourcePath(source.sourcePath)
    if (sourcePath.length === 0)
        return { accepted: false, error: "Copy source must be absolute",
            plan: null }
    const role = String(source.role || "")
    if (["media", "audio", "script"].indexOf(role) < 0)
        return { accepted: false, error: "Only source assets may be copied",
            plan: null }
    const assetId = ProjectModel.identifier(source.assetId, "")
    if (role !== "script" && assetId.length === 0)
        return { accepted: false, error: "Copied asset identity is missing",
            plan: null }
    if (parsed.document.workspace.files.some(file =>
            file.originalSourcePath === sourcePath
                && file.state !== "failed"))
        return { accepted: false, error: "Source is already embedded",
            plan: null }
    const relativePath = availableRelativePath(role, sourcePath,
        parsed.document)
    if (relativePath.length === 0)
        return { accepted: false, error: "No safe draft destination is available",
            plan: null }
    const used = usedIds || ({})
    const baseId = ProjectModel.identifier(source.fileId || assetId
        || safeFileName(sourcePath), "embedded-file")
    let fileId = baseId
    let suffix = 1
    while (used[fileId] || parsed.document.workspace.files.some(
            file => file.id === fileId)) {
        suffix += 1
        fileId = (baseId + "-" + suffix).slice(0, 96)
    }
    const rootPath = ProjectModel.normalizedSourcePath(entry.rootPath)
    if (rootPath.length === 0)
        return { accepted: false, error: "Draft root is unavailable", plan: null }
    const destinationPath = rootPath + "/" + relativePath
    return { accepted: true, error: "", plan: {
        fileId: fileId,
        workspaceId: entry.id,
        projectId: entry.projectId,
        assetId: assetId,
        role: role,
        sourcePath: sourcePath,
        relativePath: relativePath,
        destinationPath: destinationPath,
        temporaryPath: destinationPath + ".partial-" + fileId
    } }
}
