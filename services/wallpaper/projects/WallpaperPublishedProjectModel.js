.pragma library
.import "WallpaperProjectModel.js" as ProjectModel
.import "WallpaperPortableProjectModel.js" as PortableProject
.import "WallpaperProjectBundleModel.js" as Bundle

function failure(message) {
    return {
        accepted: false,
        error: String(message || "Published project is invalid"),
        projectDocument: null,
        bundleDocument: null
    };
}

function evidenceByPath(files) {
    const records = ({});
    for (const file of files || []) {
        const path = ProjectModel.normalizedPortablePath(file?.relativePath);
        if (!path || records[path])
            return null;
        records[path] = file;
    }
    return records;
}

function validate(request) {
    const source = request || ({});
    const rootPath = ProjectModel.normalizedSourcePath(source.rootPath);
    if (!rootPath)
        return failure("Project folder must be absolute");
    if (Array.isArray(source.symlinks) && source.symlinks.length > 0)
        return failure("Project folder contains a symbolic link");

    const portable = PortableProject.parse(source.projectManifest);
    if (!portable.accepted)
        return failure(portable.error);
    const bundle = Bundle.parse(source.bundleManifest);
    if (!bundle.accepted)
        return failure(bundle.error);
    const workspace = bundle.document.workspace;
    if (workspace.state !== "saved")
        return failure("Project bundle is not in a saved state");
    if (workspace.projectId !== portable.document.projectId)
        return failure("Project and bundle identities do not match");

    const evidence = evidenceByPath(source.files);
    if (!evidence)
        return failure("Project file evidence is malformed");
    const expectedCount = workspace.files.length + 2;
    if (Object.keys(evidence).length !== expectedCount || !evidence["project.json"] || !evidence["bundle.json"])
        return failure("Project file inventory does not match its bundle");

    const activeAssets = ({});
    const primaryFiles = ({});
    const project = portable.document.projectDocument.project;
    for (const asset of project.assets)
        activeAssets[asset.id] = asset;
    for (const file of workspace.files) {
        if (!activeAssets[file.assetId])
            return failure("Bundle contains an unreferenced project file");
        const physical = evidence[file.relativePath];
        if (!physical)
            return failure("Required project file is missing: " + file.relativePath);
        if (file.state !== "ready" || Number(physical.sizeBytes) !== Number(file.sizeBytes) || String(physical.identity || "").toLowerCase() !== String(file.identity || "").toLowerCase())
            return failure("Project file evidence does not match: " + file.relativePath);
        if (file.role === "media") {
            if (primaryFiles[file.assetId])
                return failure("Project asset has multiple primary files: " + file.assetId);
            primaryFiles[file.assetId] = file;
        }
    }
    for (const asset of project.assets) {
        const primary = primaryFiles[asset.id];
        if (!primary || primary.relativePath !== asset.portablePath)
            return failure("Project asset does not match its portable file: " + asset.id);
    }

    const hydrated = JSON.parse(JSON.stringify(portable.document.projectDocument));
    hydrated.project.rootPath = rootPath;
    hydrated.project.assets = hydrated.project.assets.map(asset => Object.assign({}, asset, {
            sourcePath: rootPath + "/" + asset.portablePath,
            availability: "unresolved"
        }));
    const normalized = ProjectModel.parse(hydrated);
    if (!normalized.accepted)
        return failure(normalized.error);
    return {
        accepted: true,
        error: "",
        projectDocument: normalized.document,
        bundleDocument: bundle.document
    };
}
