.pragma library

.import "WallpaperProjectModel.js" as ProjectModel
.import "WallpaperProjectBundleModel.js" as Bundle

var thumbnailRecipe = "thumbnail-480x270-png-v1"
var proxyRecipe = "proxy-1280x720-h264-v1"

function failure(message) {
    return { accepted: false, error: String(message || "Invalid derivative"),
        reused: false, plan: null }
}

function derivativeRole(value) {
    const role = String(value || "")
    return role === "thumbnail" || role === "proxy" ? role : ""
}

function recipeFor(role, value) {
    const fallback = role === "thumbnail" ? thumbnailRecipe : proxyRecipe
    const requested = ProjectModel.text(value || fallback, 128)
    return requested === fallback ? requested : ""
}

function create(request, workspace, manifest) {
    const source = request || ({})
    const entry = workspace || ({})
    const parsed = Bundle.parse(manifest)
    if (!parsed.accepted) return failure(parsed.error)
    const document = parsed.document
    if (document.workspace.id !== String(entry.id || "")
            || document.workspace.projectId !== String(entry.projectId || ""))
        return failure("Draft identity does not match")

    const role = derivativeRole(source.role)
    if (role.length === 0)
        return failure("Only thumbnail or proxy derivatives may be planned")
    const assetId = ProjectModel.identifier(source.assetId, "")
    if (assetId.length === 0)
        return failure("Derivative asset identity is missing")

    const sourceFile = document.workspace.files.find(file =>
        file.assetId === assetId
            && ["media", "audio", "script"].indexOf(file.role) >= 0)
    if (!sourceFile || sourceFile.state !== "ready")
        return failure("A ready embedded source is required")
    if (!/^sha256:[0-9a-f]{64}$/.test(sourceFile.identity))
        return failure("Embedded source identity is unavailable")

    const rootPath = ProjectModel.normalizedSourcePath(entry.rootPath)
    if (rootPath.length === 0)
        return failure("Draft root is unavailable")
    const sourcePath = rootPath + "/" + sourceFile.relativePath
    const recipe = recipeFor(role, source.recipe)
    if (recipe.length === 0)
        return failure("Derivative recipe is unsupported")
    const derivativeIdentity = Qt.md5(role + "|" + assetId + "|"
        + sourceFile.identity + "|" + recipe)
    const extension = role === "thumbnail" ? ".png" : ".mp4"
    const directory = Bundle.roleDirectory(role)
    const baseId = ProjectModel.identifier(role + "-" + assetId + "-"
        + derivativeIdentity.slice(0, 16), role + "-derivative")
    const baseName = assetId + "-" + derivativeIdentity.slice(0, 16)

    const expectedRelativePath = directory + "/" + baseName + extension
    const reusable = document.workspace.files.find(file =>
        file.role === role && file.assetId === assetId
            && file.id === baseId && file.relativePath === expectedRelativePath
            && file.state === "ready"
            && /^sha256:[0-9a-f]{64}$/.test(file.identity))
    if (reusable) return {
        accepted: true, error: "", reused: true,
        plan: {
            fileId: reusable.id, workspaceId: entry.id,
            projectId: entry.projectId, assetId: assetId, role: role,
            sourcePath: sourcePath, relativePath: reusable.relativePath,
            outputPath: rootPath + "/" + reusable.relativePath,
            temporaryPath: "", sourceIdentity: sourceFile.identity,
            derivativeIdentity: derivativeIdentity, recipe: recipe
        }
    }

    const usedIds = ({})
    const usedPaths = ({})
    for (const file of document.workspace.files) {
        usedIds[file.id] = true
        usedPaths[file.relativePath] = true
    }
    let suffix = 1
    let fileId = baseId
    let relativePath = expectedRelativePath
    while ((usedIds[fileId] || usedPaths[relativePath])
            && suffix <= Bundle.maximumFiles + 1) {
        suffix += 1
        fileId = (baseId + "-" + suffix).slice(0, 96)
        relativePath = directory + "/" + baseName + "-" + suffix + extension
    }
    if (usedIds[fileId] || usedPaths[relativePath])
        return failure("No safe derivative destination is available")

    return {
        accepted: true, error: "", reused: false,
        plan: {
            fileId: fileId, workspaceId: entry.id,
            projectId: entry.projectId, assetId: assetId, role: role,
            sourcePath: sourcePath, relativePath: relativePath,
            outputPath: rootPath + "/" + relativePath,
            temporaryPath: rootPath + "/" + directory + "/" + baseName
                + (suffix > 1 ? "-" + suffix : "") + ".partial-" + fileId
                + extension,
            sourceIdentity: sourceFile.identity,
            derivativeIdentity: derivativeIdentity, recipe: recipe
        }
    }
}
