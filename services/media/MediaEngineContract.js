.pragma library

var maximumPathLength = 4096
var maximumTimestampMs = 604800000

function text(value) {
    return String(value || "").trim()
}

function finite(value, fallback) {
    const parsed = Number(value)
    return Number.isFinite(parsed) ? parsed : fallback
}

function capabilities(value) {
    const source = value || ({})
    return {
        available: source.available === true,
        metadata: source.metadata === true,
        keyframeIndex: source.keyframeIndex === true,
        frameExtraction: source.frameExtraction === true,
        hardwareDecode: source.hardwareDecode === true,
        reason: text(source.reason)
    }
}

function frameRequest(generation, path, timestampMs) {
    const normalizedPath = text(path)
    const timestamp = Math.max(0, Math.min(maximumTimestampMs,
        Math.round(finite(timestampMs, 0))))
    return {
        generation: Math.max(0, Math.round(finite(generation, 0))),
        path: normalizedPath,
        timestampMs: timestamp,
        valid: normalizedPath.length > 0
            && normalizedPath.length <= maximumPathLength
    }
}

function requestIsCurrent(requested, completed) {
    if (!requested?.valid || !completed)
        return false
    return Number(completed.generation) === requested.generation
        && text(completed.path) === requested.path
        && Math.round(finite(completed.timestampMs, -1))
            === requested.timestampMs
}

function metadataRequest(generation, path) {
    const normalizedPath = text(path)
    return {
        generation: Math.max(0, Math.round(finite(generation, 0))),
        path: normalizedPath,
        valid: normalizedPath.length > 0
            && normalizedPath.length <= maximumPathLength
    }
}
