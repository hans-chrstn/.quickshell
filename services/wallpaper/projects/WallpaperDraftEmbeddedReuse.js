.pragma library

.import "WallpaperProjectModel.js" as ProjectModel
.import "WallpaperProjectBundleModel.js" as Bundle

function resolve(candidate, workspace, manifest, projectDocument) {
    const sourcePath = ProjectModel.normalizedSourcePath(candidate?.sourcePath)
    const requestedAssetId = ProjectModel.identifier(candidate?.assetId, "")
    const rootPath = ProjectModel.normalizedSourcePath(workspace?.rootPath)
    const bundle = Bundle.parse(manifest)
    const project = ProjectModel.parse(projectDocument)
    if (sourcePath.length === 0 || requestedAssetId.length === 0
            || rootPath.length === 0 || !bundle.accepted || !project.accepted
            || bundle.document.workspace.id !== String(workspace?.id || "")
            || bundle.document.workspace.projectId
                !== project.document.project.id)
        return { accepted: false, found: false,
            error: "Embedded reuse input is invalid", asset: null }

    const file = bundle.document.workspace.files.find(record =>
        record.role === "media" && record.state === "ready"
            && record.originalSourcePath === sourcePath)
    if (!file) return { accepted: true, found: false, error: "", asset: null }
    if (!/^sha256:[0-9a-f]{64}$/.test(file.identity))
        return { accepted: false, found: true,
            error: "Embedded copy identity is unavailable", asset: null }
    if (requestedAssetId !== file.assetId)
        return { accepted: false, found: true,
            error: "Embedded asset identity conflicts with the project", asset: null }
    if (project.document.project.assets.some(asset => asset.id === file.assetId))
        return { accepted: false, found: true,
            error: "Embedded asset is already attached to the project", asset: null }

    return { accepted: true, found: true, error: "", asset: {
        assetId: file.assetId,
        name: String(candidate?.name || "") || "Untitled Asset",
        sourcePath: rootPath + "/" + file.relativePath,
        portablePath: file.relativePath,
        reused: true
    } }
}
