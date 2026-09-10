.pragma library

.import "WallpaperProjectModel.js" as ProjectModel

var schemaVersion = 1
var maximumFiles = 2048
var maximumErrorLength = 512
var directoryNames = ({
    media: "media",
    audio: "audio",
    scripts: "scripts",
    thumbnails: "thumbnails",
    proxies: "proxies"
})

function collection(value) {
    return Array.isArray(value) ? value : []
}

function absolutePath(value) {
    return ProjectModel.normalizedSourcePath(value)
}

function relativePath(value) {
    return ProjectModel.normalizedPortablePath(value)
}

function roleDirectory(role) {
    if (role === "media") return directoryNames.media
    if (role === "audio") return directoryNames.audio
    if (role === "script") return directoryNames.scripts
    if (role === "thumbnail") return directoryNames.thumbnails
    if (role === "proxy") return directoryNames.proxies
    return ""
}

function safeRolePath(role, value) {
    const path = relativePath(value)
    const directory = roleDirectory(role)
    return directory.length > 0 && path.startsWith(directory + "/")
            && path.length > directory.length + 1
        ? path : ""
}

function normalizeFile(value, index) {
    const source = value || ({})
    const role = ProjectModel.enumValue(source.role,
        ["media", "audio", "script", "thumbnail", "proxy"], "media")
    return {
        id: ProjectModel.identifier(source.id, "file-" + (index + 1)),
        assetId: ProjectModel.identifier(source.assetId, ""),
        role: role,
        relativePath: safeRolePath(role, source.relativePath),
        originalSourcePath: ["media", "audio", "script"].indexOf(role) >= 0
            ? absolutePath(source.originalSourcePath) : "",
        sizeBytes: ProjectModel.integer(source.sizeBytes, 0,
            Number.MAX_SAFE_INTEGER, 0),
        identity: ProjectModel.text(source.identity, 256),
        state: ProjectModel.enumValue(source.state,
            ["pending", "copying", "ready", "failed"], "pending"),
        error: ProjectModel.text(source.error, maximumErrorLength)
    }
}

function normalizeDocument(value) {
    const source = value || ({})
    const workspace = source.workspace || ({})
    return {
        schemaVersion: schemaVersion,
        workspace: {
            id: ProjectModel.identifier(workspace.id, "draft-workspace"),
            projectId: ProjectModel.identifier(workspace.projectId,
                "wallpaper-project"),
            state: ProjectModel.enumValue(workspace.state,
                ["draft", "saving", "saved", "failed"], "draft"),
            createdAtMs: ProjectModel.integer(workspace.createdAtMs, 0,
                Number.MAX_SAFE_INTEGER, 0),
            updatedAtMs: ProjectModel.integer(workspace.updatedAtMs, 0,
                Number.MAX_SAFE_INTEGER, 0),
            revision: ProjectModel.integer(workspace.revision, 0,
                Number.MAX_SAFE_INTEGER, 0),
            savedRevision: ProjectModel.integer(workspace.savedRevision, 0,
                Number.MAX_SAFE_INTEGER, 0),
            destinationPath: absolutePath(workspace.destinationPath),
            lastError: ProjectModel.text(workspace.lastError,
                maximumErrorLength),
            files: collection(workspace.files).map(normalizeFile)
        }
    }
}

function validate(value) {
    const errors = []
    if (!value || typeof value !== "object" || Array.isArray(value))
        return { accepted: false,
            errors: ["Bundle manifest must be an object"] }
    const version = Math.floor(Number(value.schemaVersion) || 0)
    if (version > schemaVersion)
        return { accepted: false,
            errors: ["Unsupported future bundle version " + version] }
    if (version < schemaVersion)
        return { accepted: false,
            errors: ["Unsupported legacy bundle version " + version] }
    if (!value.workspace || typeof value.workspace !== "object"
            || Array.isArray(value.workspace))
        errors.push("Bundle workspace record is missing")
    const workspace = value.workspace || ({})
    if (ProjectModel.identifier(workspace.id, "").length === 0)
        errors.push("Bundle workspace id is missing")
    if (ProjectModel.identifier(workspace.projectId, "").length === 0)
        errors.push("Bundle project id is missing")
    if (["draft", "saving", "saved", "failed"].indexOf(
            String(workspace.state || "")) < 0)
        errors.push("Bundle workspace state is invalid")
    if (workspace.destinationPath
            && absolutePath(workspace.destinationPath).length === 0)
        errors.push("Bundle destination path must be absolute")
    if ((Number(workspace.savedRevision) || 0)
            > (Number(workspace.revision) || 0))
        errors.push("Bundle saved revision exceeds current revision")
    if (value.workspace?.files !== undefined
            && !Array.isArray(value.workspace.files))
        errors.push("Bundle files must be an array")
    const files = collection(value.workspace?.files)
    if (files.length > maximumFiles) errors.push("Bundle file limit exceeded")
    const ids = ({})
    const paths = ({})
    for (let index = 0; index < files.length; ++index) {
        const source = files[index] || ({})
        if (ProjectModel.identifier(source.id, "").length === 0)
            errors.push("Bundle file id is missing at index " + index)
        if (["media", "audio", "script", "thumbnail", "proxy"].indexOf(
                String(source.role || "")) < 0)
            errors.push("Bundle file role is invalid at index " + index)
        if (["pending", "copying", "ready", "failed"].indexOf(
                String(source.state || "")) < 0)
            errors.push("Bundle file state is invalid at index " + index)
        const file = normalizeFile(files[index], index)
        if (ids[file.id]) errors.push("Duplicate bundle file id: " + file.id)
        ids[file.id] = true
        if (file.relativePath.length === 0)
            errors.push("Bundle file has an unsafe role path: " + file.id)
        else if (paths[file.relativePath])
            errors.push("Duplicate bundle path: " + file.relativePath)
        paths[file.relativePath] = true
        if (["media", "audio", "script"].indexOf(file.role) >= 0
                && file.originalSourcePath.length === 0)
            errors.push("Embedded source path is missing: " + file.id)
        if (["thumbnail", "proxy"].indexOf(file.role) >= 0
                && file.assetId.length === 0)
            errors.push("Generated file asset is missing: " + file.id)
    }
    return { accepted: errors.length === 0, errors: errors }
}

function parse(value) {
    const validation = validate(value)
    if (!validation.accepted)
        return { accepted: false, error: validation.errors.join("; "),
            errors: validation.errors, document: null }
    return { accepted: true, error: "", errors: [],
        document: normalizeDocument(value) }
}

function create(workspaceId, projectId, nowMs) {
    const now = ProjectModel.integer(nowMs, 0,
        Number.MAX_SAFE_INTEGER, 0)
    return normalizeDocument({ schemaVersion: schemaVersion, workspace: {
        id: workspaceId,
        projectId: projectId,
        state: "draft",
        createdAtMs: now,
        updatedAtMs: now,
        revision: 0,
        savedRevision: 0,
        destinationPath: "",
        lastError: "",
        files: []
    } })
}

function appendFile(document, value, nowMs) {
    const parsed = parse(document)
    if (!parsed.accepted) return parsed
    if (parsed.document.workspace.files.length >= maximumFiles)
        return { accepted: false, error: "Bundle file limit reached",
            errors: ["Bundle file limit reached"], document: null }
    const workspace = parsed.document.workspace
    const candidateValidation = validate({ schemaVersion: schemaVersion,
        workspace: Object.assign({}, workspace, {
            files: workspace.files.concat([value])
        })
    })
    if (!candidateValidation.accepted)
        return { accepted: false,
            error: candidateValidation.errors.join("; "),
            errors: candidateValidation.errors, document: null }
    const candidate = normalizeFile(value, workspace.files.length)
    const trial = normalizeDocument(parsed.document)
    trial.workspace.files = workspace.files.concat([candidate])
    trial.workspace.state = "draft"
    trial.workspace.updatedAtMs = ProjectModel.integer(nowMs, 0,
        Number.MAX_SAFE_INTEGER, workspace.updatedAtMs)
    trial.workspace.revision += 1
    trial.workspace.lastError = ""
    return parse(trial)
}

function updateFile(document, fileId, changes, nowMs) {
    const parsed = parse(document)
    if (!parsed.accepted) return parsed
    const id = ProjectModel.identifier(fileId, "")
    const index = parsed.document.workspace.files.findIndex(
        file => file.id === id)
    if (index < 0)
        return { accepted: false, error: "Bundle file was not found",
            errors: ["Bundle file was not found"], document: null }
    const current = parsed.document.workspace.files[index]
    const allowed = changes || ({})
    const candidate = Object.assign({}, current, {
        sizeBytes: allowed.sizeBytes === undefined
            ? current.sizeBytes : allowed.sizeBytes,
        identity: allowed.identity === undefined
            ? current.identity : allowed.identity,
        state: allowed.state === undefined ? current.state : allowed.state,
        error: allowed.error === undefined ? current.error : allowed.error
    })
    const trial = normalizeDocument(parsed.document)
    trial.workspace.files[index] = candidate
    trial.workspace.state = "draft"
    trial.workspace.updatedAtMs = ProjectModel.integer(nowMs, 0,
        Number.MAX_SAFE_INTEGER, trial.workspace.updatedAtMs)
    trial.workspace.revision += 1
    trial.workspace.lastError = candidate.state === "failed"
        ? ProjectModel.text(candidate.error, maximumErrorLength) : ""
    return parse(trial)
}

function removeFile(document, fileId, nowMs) {
    const parsed = parse(document)
    if (!parsed.accepted) return parsed
    const id = ProjectModel.identifier(fileId, "")
    const index = parsed.document.workspace.files.findIndex(
        file => file.id === id)
    if (index < 0)
        return { accepted: false, error: "Bundle file was not found",
            errors: ["Bundle file was not found"], document: null }
    const trial = normalizeDocument(parsed.document)
    trial.workspace.files.splice(index, 1)
    trial.workspace.state = "draft"
    trial.workspace.updatedAtMs = ProjectModel.integer(nowMs, 0,
        Number.MAX_SAFE_INTEGER, trial.workspace.updatedAtMs)
    trial.workspace.revision += 1
    trial.workspace.lastError = ""
    return parse(trial)
}

function beginSave(document, destinationPath, nowMs) {
    const parsed = parse(document)
    if (!parsed.accepted) return parsed
    const destination = absolutePath(destinationPath)
    if (destination.length === 0)
        return { accepted: false, error: "Save destination must be absolute",
            errors: ["Save destination must be absolute"], document: null }
    const pending = parsed.document.workspace.files.some(
        file => file.state !== "ready")
    if (pending)
        return { accepted: false, error: "Bundle contains incomplete files",
            errors: ["Bundle contains incomplete files"], document: null }
    parsed.document.workspace.state = "saving"
    parsed.document.workspace.destinationPath = destination
    parsed.document.workspace.updatedAtMs = ProjectModel.integer(nowMs, 0,
        Number.MAX_SAFE_INTEGER, parsed.document.workspace.updatedAtMs)
    parsed.document.workspace.lastError = ""
    return parsed
}

function completeSave(document, nowMs) {
    const parsed = parse(document)
    if (!parsed.accepted) return parsed
    if (parsed.document.workspace.state !== "saving")
        return { accepted: false, error: "Bundle is not being saved",
            errors: ["Bundle is not being saved"], document: null }
    const workspace = parsed.document.workspace
    workspace.state = "saved"
    workspace.savedRevision = workspace.revision
    workspace.updatedAtMs = ProjectModel.integer(nowMs, 0,
        Number.MAX_SAFE_INTEGER, workspace.updatedAtMs)
    workspace.lastError = ""
    return parsed
}

function recoverInterrupted(document, nowMs) {
    const parsed = parse(document)
    if (!parsed.accepted) return parsed
    const workspace = parsed.document.workspace
    let interrupted = workspace.state === "saving"
    workspace.files = workspace.files.map(file => {
        if (file.state !== "copying") return file
        interrupted = true
        return Object.assign({}, file, { state: "failed",
            error: "Copy interrupted before completion" })
    })
    if (interrupted) {
        workspace.state = "draft"
        workspace.lastError = "Previous file operation was interrupted"
        workspace.updatedAtMs = ProjectModel.integer(nowMs, 0,
            Number.MAX_SAFE_INTEGER, workspace.updatedAtMs)
    }
    return parsed
}
