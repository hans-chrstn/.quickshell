.pragma library

var schemaVersion = 1
var minimumDurationMs = 1000
var maximumDurationMs = 604800000
var maximumPlaylists = 64
var maximumEntriesPerPlaylist = 512
var maximumTotalEntries = 2048

function identifier(value, fallback) {
    const cleaned = String(value || "").trim()
        .replace(/[^A-Za-z0-9._-]+/g, "-")
        .replace(/^-+|-+$/g, "")
    return (cleaned.length > 0 ? cleaned : fallback).slice(0, 96)
}

function uniqueIdentifier(candidate, fallback, used) {
    const base = identifier(candidate, fallback)
    let result = base
    let suffix = 2
    while (used[result]) {
        result = base + "-" + suffix
        suffix += 1
    }
    used[result] = true
    return result
}

function duration(value) {
    if (value === undefined || value === null || Number(value) === 0)
        return 0
    const numeric = Number(value)
    if (!Number.isFinite(numeric))
        return 0
    return Math.round(Math.max(minimumDurationMs,
        Math.min(maximumDurationMs, numeric)))
}

function normalizeEntries(values, playlistId, available) {
    const result = []
    const used = ({})
    for (let index = 0; index < (values || []).length
            && result.length < maximumEntriesPerPlaylist
            && result.length < available; ++index) {
        const source = values[index] || ({})
        const path = String(source.path || "").trim().slice(0, 4096)
        if (path.length === 0)
            continue
        result.push({
            id: uniqueIdentifier(source.id,
                playlistId + "-entry-" + (index + 1), used),
            path: path,
            durationMs: duration(source.durationMs)
        })
    }
    return result
}

function normalizePlaylists(values) {
    const result = []
    const used = ({})
    let remainingEntries = maximumTotalEntries
    for (let index = 0; index < (values || []).length
            && result.length < maximumPlaylists; ++index) {
        const source = values[index] || ({})
        const id = uniqueIdentifier(source.id,
            "playlist-" + (index + 1), used)
        const entries = normalizeEntries(source.entries, id, remainingEntries)
        remainingEntries -= entries.length
        result.push({
            id: id,
            name: String(source.name || "").trim().slice(0, 160)
                || "Untitled Playlist",
            mode: source.mode === "shuffle" ? "shuffle" : "ordered",
            seed: Math.max(0, Math.floor(Number(source.seed) || 0)),
            entries: entries
        })
    }
    return result
}

function normalizeDocument(value) {
    const source = value || ({})
    return {
        schemaVersion: schemaVersion,
        playlists: normalizePlaylists(source.playlists)
    }
}
