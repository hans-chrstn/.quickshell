.pragma library

var schemaVersion = 1
var maximumHooks = 64
var maximumArguments = 24
var maximumArgumentLength = 1024
var maximumExecutableLength = 4096
var minimumTimeoutMs = 100
var maximumTimeoutMs = 30000
var defaultTimeoutMs = 5000
var phases = ["pre-change", "post-change"]
var contextKeys = ["screen", "path", "previousPath", "source",
    "playlistId", "ruleId", "entryId", "reason"]

function identifier(value, fallback) {
    const cleaned = String(value || "").trim()
        .replace(/[^A-Za-z0-9._-]+/g, "-")
        .replace(/^-+|-+$/g, "")
    return (cleaned.length > 0 ? cleaned : fallback).slice(0, 96)
}

function executable(value) {
    const path = String(value || "").trim().slice(0, maximumExecutableLength)
    return path.startsWith("/") && path.indexOf("\0") < 0 ? path : ""
}

function timeout(value) {
    const number = Math.floor(Number(value))
    return Number.isFinite(number)
        ? Math.max(minimumTimeoutMs, Math.min(maximumTimeoutMs, number))
        : defaultTimeoutMs
}

function argumentsList(values) {
    const result = []
    if (!Array.isArray(values))
        return result
    for (let index = 0; index < values.length
            && result.length < maximumArguments; ++index) {
        const value = String(values[index] ?? "")
            .replace(/\0/g, "").slice(0, maximumArgumentLength)
        result.push(value)
    }
    return result
}

function normalizeHooks(values) {
    const result = []
    const used = ({})
    for (let index = 0; index < (values || []).length
            && result.length < maximumHooks; ++index) {
        const source = values[index] || ({})
        const path = executable(source.executable)
        const phase = String(source.phase || "")
        if (path.length === 0 || phases.indexOf(phase) < 0)
            continue
        const base = identifier(source.id, "hook-" + (index + 1))
        let id = base
        let suffix = 2
        while (used[id]) {
            id = base + "-" + suffix
            suffix += 1
        }
        used[id] = true
        result.push({
            id: id,
            name: String(source.name || "").trim().slice(0, 160)
                || "Untitled Hook",
            enabled: source.enabled === true,
            phase: phase,
            executable: path,
            arguments: argumentsList(source.arguments),
            screenName: String(source.screenName || "").trim().slice(0, 128),
            timeoutMs: timeout(source.timeoutMs),
            priority: Math.max(-1000, Math.min(1000,
                Math.floor(Number(source.priority) || 0)))
        })
    }
    return result
}

function normalizeDocument(value) {
    return { schemaVersion: schemaVersion, hooks: normalizeHooks(value?.hooks) }
}

function boundedContext(value) {
    const source = value || ({})
    const result = ({})
    for (const key of contextKeys)
        result[key] = String(source[key] ?? "").slice(0, 4096)
    return result
}

function expandArgument(template, context) {
    const values = boundedContext(context)
    return String(template ?? "").replace(/\{([A-Za-z]+)\}/g,
        function(match, key) {
            return contextKeys.indexOf(key) >= 0 ? values[key] : match
        }).slice(0, 8192)
}

function selected(values, phaseValue, screenValue) {
    const phase = String(phaseValue || "")
    const screen = String(screenValue || "").trim().slice(0, 128)
    return (values || []).filter(hook => hook.enabled === true
        && hook.phase === phase
        && (hook.screenName.length === 0 || hook.screenName === screen))
        .slice().sort((first, second) => {
            const priority = Number(second.priority) - Number(first.priority)
            if (priority !== 0)
                return priority
            return first.id < second.id ? -1 : first.id > second.id ? 1 : 0
        })
}

function invocation(hook, context) {
    if (!hook || hook.enabled !== true)
        return null
    const path = executable(hook.executable)
    if (path.length === 0)
        return null
    const args = argumentsList(hook.arguments)
        .map(value => expandArgument(value, context))
    return {
        hookId: String(hook.id || ""),
        executable: path,
        arguments: args,
        command: [path].concat(args),
        timeoutMs: timeout(hook.timeoutMs)
    }
}
