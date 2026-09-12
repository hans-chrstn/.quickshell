.pragma library

var schemaVersion = 1
var maximumAssets = 512
var maximumTracks = 64
var maximumClips = 4096
var maximumMarkers = 512
var maximumProperties = 128
var maximumOutputs = 32
var maximumProjectDurationMs = 604800000

function text(value, maximum) {
    return String(value || "").trim().slice(0, maximum)
}

function identifier(value, fallback) {
    const cleaned = text(value, 160)
        .replace(/[^A-Za-z0-9._-]+/g, "-")
        .replace(/^-+|-+$/g, "")
    return (cleaned || fallback).slice(0, 96)
}

function number(value, minimum, maximum, fallback) {
    const numeric = Number(value)
    if (!Number.isFinite(numeric))
        return fallback
    return Math.max(minimum, Math.min(maximum, numeric))
}

function integer(value, minimum, maximum, fallback) {
    return Math.round(number(value, minimum, maximum, fallback))
}

function normalizedSourcePath(value) {
    let path = text(value, 4096)
    if (path.startsWith("file://")) {
        try {
            path = decodeURIComponent(path.slice(7))
        } catch (error) {
            return ""
        }
    }
    if (!path.startsWith("/"))
        return ""
    return path.replace(/\/{2,}/g, "/")
}

function normalizedPortablePath(value) {
    const parts = text(value, 2048).replace(/\\/g, "/")
        .split("/").filter(part => part.length > 0 && part !== ".")
    if (parts.length === 0 || parts.some(part => part === ".."))
        return ""
    return parts.join("/")
}

function enumValue(value, allowed, fallback) {
    const candidate = String(value || "")
    return allowed.indexOf(candidate) >= 0 ? candidate : fallback
}

function collection(value) {
    return Array.isArray(value) ? value : []
}

function duplicateIds(values, namespace, errors) {
    const used = ({})
    for (let index = 0; index < values.length; ++index) {
        const id = identifier(values[index]?.id, "")
        if (id.length === 0)
            continue
        if (used[id])
            errors.push("Duplicate " + namespace + " id: " + id)
        used[id] = true
    }
}

function migrate(value) {
    if (!value || typeof value !== "object" || Array.isArray(value))
        return { accepted: false, error: "Project document must be an object",
            document: null, migratedFrom: -1 }
    const source = value && typeof value === "object" ? value : ({})
    const version = integer(source.schemaVersion, 0, 1000000, 0)
    if (version > schemaVersion)
        return { accepted: false, error: "Unsupported future project version "
            + version, document: null, migratedFrom: version }
    if (version === schemaVersion)
        return { accepted: true, error: "", document: source,
            migratedFrom: schemaVersion }

    return {
        accepted: true,
        error: "",
        migratedFrom: version,
        document: {
            schemaVersion: schemaVersion,
            project: {
                id: source.id,
                name: source.name,
                createdAtMs: source.createdAtMs,
                updatedAtMs: source.updatedAtMs,
                durationMs: source.durationMs,
                rootPath: source.rootPath,
                assets: source.assets,
                tracks: source.tracks,
                markers: source.markers,
                userProperties: source.userProperties || source.properties,
                outputTargets: source.outputTargets || source.outputs
            }
        }
    }
}

function validateDocument(value) {
    const migrated = migrate(value)
    if (!migrated.accepted)
        return { accepted: false, errors: [migrated.error],
            migratedFrom: migrated.migratedFrom }
    const project = migrated.document?.project
    const errors = []
    if (!project || typeof project !== "object")
        errors.push("Project record is missing")
    for (const field of ["assets", "tracks", "markers", "userProperties",
            "outputTargets"]) {
        if (project?.[field] !== undefined && !Array.isArray(project[field]))
            errors.push("Project " + field + " must be an array")
    }
    const assets = collection(project?.assets)
    const tracks = collection(project?.tracks)
    const markers = collection(project?.markers)
    const properties = collection(project?.userProperties)
    const outputs = collection(project?.outputTargets)
    if (assets.length > maximumAssets) errors.push("Asset limit exceeded")
    if (tracks.length > maximumTracks) errors.push("Track limit exceeded")
    if (markers.length > maximumMarkers) errors.push("Marker limit exceeded")
    if (properties.length > maximumProperties)
        errors.push("User-property limit exceeded")
    if (outputs.length > maximumOutputs) errors.push("Output limit exceeded")
    duplicateIds(assets, "asset", errors)
    duplicateIds(tracks, "track", errors)
    duplicateIds(markers, "marker", errors)
    duplicateIds(properties, "property", errors)
    duplicateIds(outputs, "output", errors)

    const assetIds = ({})
    for (const asset of assets) {
        const id = identifier(asset?.id, "")
        if (id.length > 0) assetIds[id] = true
    }
    const clipIds = ({})
    let clipCount = 0
    for (const track of tracks) {
        if (track?.clips !== undefined && !Array.isArray(track.clips)) {
            errors.push("Track clips must be an array")
            continue
        }
        for (const clip of collection(track?.clips)) {
            clipCount += 1
            const clipId = identifier(clip?.id, "")
            if (clipId.length > 0 && clipIds[clipId])
                errors.push("Duplicate clip id: " + clipId)
            if (clipId.length > 0) clipIds[clipId] = true
            const assetId = identifier(clip?.assetId, "")
            if (assetId.length === 0 || !assetIds[assetId])
                errors.push("Clip " + (clipId || "without id")
                    + " references a missing asset")
        }
    }
    if (clipCount > maximumClips) errors.push("Clip limit exceeded")
    return { accepted: errors.length === 0, errors: errors,
        migratedFrom: migrated.migratedFrom }
}

function normalizeAsset(value, index) {
    const source = value || ({})
    return {
        id: identifier(source.id, "asset-" + (index + 1)),
        name: text(source.name, 160) || "Untitled Asset",
        kind: enumValue(source.kind || source.type,
            ["static", "animated-image", "video", "unknown"], "unknown"),
        sourcePath: normalizedSourcePath(source.sourcePath || source.path),
        portablePath: normalizedPortablePath(source.portablePath),
        availability: enumValue(source.availability,
            ["unresolved", "available", "missing"],
            source.missing === true ? "missing" : "unresolved")
    }
}

function normalizeClip(value, trackId, index) {
    const source = value || ({})
    return {
        id: identifier(source.id, trackId + "-clip-" + (index + 1)),
        assetId: identifier(source.assetId, ""),
        startMs: integer(source.startMs, 0, maximumProjectDurationMs, 0),
        durationMs: integer(source.durationMs, 1,
            maximumProjectDurationMs, 1000),
        sourceInMs: integer(source.sourceInMs, 0,
            maximumProjectDurationMs, 0),
        loop: source.loop === true,
        enabled: source.enabled !== false
    }
}

function normalizeTrack(value, index) {
    const source = value || ({})
    const id = identifier(source.id, "track-" + (index + 1))
    return {
        id: id,
        name: text(source.name, 160) || "Untitled Track",
        type: enumValue(source.type,
            ["media", "transition", "trigger", "audio"], "media"),
        enabled: source.enabled !== false,
        clips: collection(source.clips).map((clip, clipIndex) =>
            normalizeClip(clip, id, clipIndex))
    }
}

function normalizeMarker(value, index) {
    const source = value || ({})
    return {
        id: identifier(source.id, "marker-" + (index + 1)),
        name: text(source.name, 160) || "Untitled Marker",
        timeMs: integer(source.timeMs, 0, maximumProjectDurationMs, 0),
        triggerType: enumValue(source.triggerType,
            ["manual", "time", "date", "weather", "battery", "workspace",
                "application", "window", "media", "session", "monitor"],
            "manual"),
        enabled: source.enabled !== false
    }
}

function propertyDefault(type, value) {
    if (type === "toggle") return value === true
    if (type === "number") return number(value, -1000000, 1000000, 0)
    return text(value, type === "text" ? 2048 : 256)
}

function normalizeProperty(value, index) {
    const source = value || ({})
    const type = enumValue(source.type,
        ["toggle", "number", "choice", "color", "text", "media"], "text")
    return {
        id: identifier(source.id, "property-" + (index + 1)),
        name: text(source.name, 160) || "Untitled Property",
        type: type,
        defaultValue: propertyDefault(type, source.defaultValue),
        group: text(source.group, 96)
    }
}

function normalizeOutput(value, index) {
    const source = value || ({})
    return {
        id: identifier(source.id, "output-" + (index + 1)),
        screenName: text(source.screenName, 128),
        fit: enumValue(source.fit, ["cover", "contain", "stretch"], "cover"),
        width: integer(source.width, 0, 16384, 0),
        height: integer(source.height, 0, 16384, 0)
    }
}

function requirements(project) {
    const assets = project.assets
    const markers = project.markers
    return {
        staticImages: assets.some(asset => asset.kind === "static"),
        animatedImages: assets.some(asset => asset.kind === "animated-image"),
        video: assets.some(asset => asset.kind === "video"),
        audio: project.tracks.some(track => track.type === "audio"),
        triggers: markers.some(marker => marker.enabled),
        scripts: false
    }
}

function normalizeDocument(value) {
    const migrated = migrate(value)
    if (!migrated.accepted)
        return null
    const source = migrated.document.project || ({})
    const project = {
        id: identifier(source.id, "wallpaper-project"),
        name: text(source.name, 160) || "Untitled Wallpaper",
        createdAtMs: integer(source.createdAtMs, 0,
            Number.MAX_SAFE_INTEGER, 0),
        updatedAtMs: integer(source.updatedAtMs, 0,
            Number.MAX_SAFE_INTEGER, 0),
        durationMs: integer(source.durationMs, 0,
            maximumProjectDurationMs, 0),
        rootPath: normalizedSourcePath(source.rootPath),
        assets: collection(source.assets).map(normalizeAsset),
        tracks: collection(source.tracks).map(normalizeTrack),
        markers: collection(source.markers).map(normalizeMarker),
        userProperties: collection(source.userProperties).map(normalizeProperty),
        outputTargets: collection(source.outputTargets).map(normalizeOutput)
    }
    project.runtimeRequirements = requirements(project)
    return { schemaVersion: schemaVersion, project: project }
}

function parse(value) {
    const validation = validateDocument(value)
    if (!validation.accepted)
        return { accepted: false, error: validation.errors.join("; "),
            errors: validation.errors, document: null,
            migratedFrom: validation.migratedFrom }
    return { accepted: true, error: "", errors: [],
        document: normalizeDocument(value), migratedFrom: validation.migratedFrom }
}

function relinkAsset(document, assetId, sourcePath, portablePath) {
    const parsed = parse(document)
    if (!parsed.accepted)
        return parsed
    const targetId = identifier(assetId, "")
    let found = false
    const updated = parsed.document.project.assets.map(asset => {
        if (asset.id !== targetId) return asset
        found = true
        return Object.assign({}, asset, {
            sourcePath: normalizedSourcePath(sourcePath),
            portablePath: normalizedPortablePath(portablePath),
            availability: "unresolved"
        })
    })
    if (!found)
        return { accepted: false, error: "Asset not found: " + targetId,
            errors: ["Asset not found: " + targetId], document: null,
            migratedFrom: schemaVersion }
    parsed.document.project.assets = updated
    return parsed
}

function removeAsset(document, assetId) {
    const parsed = parse(document)
    if (!parsed.accepted)
        return parsed
    const targetId = identifier(assetId, "")
    if (!parsed.document.project.assets.some(asset => asset.id === targetId))
        return { accepted: false, error: "Asset not found: " + targetId,
            errors: ["Asset not found: " + targetId], document: null,
            migratedFrom: schemaVersion }
    const referenced = parsed.document.project.tracks.some(track =>
        track.clips.some(clip => clip.assetId === targetId))
    if (referenced)
        return { accepted: false,
            error: "Asset is used by one or more timeline clips",
            errors: ["Asset is used by one or more timeline clips"],
            document: null, migratedFrom: schemaVersion }
    parsed.document.project.assets = parsed.document.project.assets.filter(
        asset => asset.id !== targetId)
    parsed.document.project.runtimeRequirements = requirements(
        parsed.document.project)
    return parsed
}
