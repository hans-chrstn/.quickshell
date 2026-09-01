pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services.wallpaper
import "WallpaperPlaylistModel.js" as PlaylistModel
import "WallpaperPlaylistOrder.js" as PlaylistOrder

Singleton {
    id: root

    property alias playlists: data.playlists
    property bool loaded: false
    property string error: ""
    property int idSequence: 0
    property bool validationActive: false
    property bool validationUpdateScheduled: false
    property var validation: ({
        state: "idle", playlists: [], total: 0, valid: 0,
        pending: 0, missing: 0, unsupported: 0, duplicate: 0, failed: 0
    })

    function nextId(prefix) {
        idSequence += 1
        return prefix + "-" + Date.now().toString(36)
            + "-" + idSequence.toString(36)
    }

    function normalizedDocument(value) {
        return PlaylistModel.normalizeDocument(value)
    }

    function resetValidation() {
        validationActive = false
        validationUpdateScheduled = false
        validation = {
            state: "idle", playlists: [], total: 0, valid: 0,
            pending: 0, missing: 0, unsupported: 0, duplicate: 0, failed: 0
        }
    }

    function replaceDocument(value) {
        if (!loaded) {
            error = "Wallpaper playlists are still loading"
            return false
        }
        if (!value || typeof value !== "object"
                || !Array.isArray(value.playlists)) {
            error = "Playlist document must contain a playlists array"
            return false
        }
        const normalized = normalizedDocument(value)
        data.schemaVersion = normalized.schemaVersion
        playlists = normalized.playlists
        resetValidation()
        error = ""
        markDirty()
        return true
    }

    function replaceJson(value) {
        try {
            return replaceDocument(JSON.parse(String(value || "")))
        } catch (exception) {
            error = "Playlist JSON is invalid"
            return false
        }
    }

    function createPlaylist(name, mode) {
        if (!loaded) {
            error = "Wallpaper playlists are still loading"
            return ""
        }
        if (playlists.length >= PlaylistModel.maximumPlaylists) {
            error = "Playlist limit reached"
            return ""
        }
        const id = nextId("playlist")
        const updated = playlists.slice()
        updated.push({
            id: id,
            name: String(name || "").trim() || "Untitled Playlist",
            mode: mode === "shuffle" ? "shuffle" : "ordered",
            seed: 0,
            entries: []
        })
        playlists = updated
        resetValidation()
        error = ""
        markDirty()
        return id
    }

    function removePlaylist(playlistId) {
        if (!loaded) {
            error = "Wallpaper playlists are still loading"
            return false
        }
        const id = String(playlistId || "").trim()
        const updated = playlists.filter(item => item.id !== id)
        if (updated.length === playlists.length)
            return false
        playlists = updated
        resetValidation()
        error = ""
        markDirty()
        return true
    }

    function playlistIndex(playlistId) {
        const id = String(playlistId || "").trim()
        return playlists.findIndex(item => item.id === id)
    }

    function resolvedEntries(playlistId) {
        const index = playlistIndex(playlistId)
        if (index < 0) {
            error = "Playlist does not exist"
            return []
        }
        error = ""
        return PlaylistOrder.resolvedEntries(playlists[index])
    }

    function playlistSnapshot(playlistId) {
        const index = playlistIndex(playlistId)
        if (index < 0)
            return null
        const playlist = playlists[index]
        return Object.assign({}, playlist, {
            entries: (playlist.entries || []).map(entry =>
                Object.assign({}, entry))
        })
    }

    function commitPlaylist(index, playlist) {
        const updated = playlists.slice()
        updated[index] = playlist
        const normalized = normalizedDocument({ playlists: updated })
        playlists = normalized.playlists
        resetValidation()
        error = ""
        markDirty()
        return true
    }

    function renamePlaylist(playlistId, name) {
        if (!loaded)
            return false
        const index = playlistIndex(playlistId)
        const normalizedName = String(name || "").trim()
        if (index < 0 || normalizedName.length === 0) {
            error = index < 0 ? "Playlist does not exist"
                : "Playlist name is required"
            return false
        }
        return commitPlaylist(index, Object.assign({}, playlists[index], {
            name: normalizedName
        }))
    }

    function configurePlaylist(playlistId, mode, seed) {
        if (!loaded)
            return false
        const index = playlistIndex(playlistId)
        if (index < 0 || (mode !== "ordered" && mode !== "shuffle")) {
            error = index < 0 ? "Playlist does not exist"
                : "Playlist mode must be ordered or shuffle"
            return false
        }
        const normalizedSeed = Math.max(0,
            Math.min(4294967295, Math.floor(Number(seed) || 0)))
        return commitPlaylist(index, Object.assign({}, playlists[index], {
            mode: mode,
            seed: normalizedSeed
        }))
    }

    function addEntry(playlistId, path, durationMs) {
        if (!loaded)
            return ""
        const index = playlistIndex(playlistId)
        const normalizedPath = String(path || "").trim()
        if (index < 0 || normalizedPath.length === 0) {
            error = index < 0 ? "Playlist does not exist"
                : "Wallpaper path is required"
            return ""
        }
        const currentEntries = playlists[index].entries || []
        let totalEntries = 0
        for (const playlist of playlists)
            totalEntries += (playlist.entries || []).length
        if (currentEntries.length >= PlaylistModel.maximumEntriesPerPlaylist
                || totalEntries >= PlaylistModel.maximumTotalEntries) {
            error = currentEntries.length
                    >= PlaylistModel.maximumEntriesPerPlaylist
                ? "Playlist entry limit reached"
                : "Total playlist entry limit reached"
            return ""
        }
        const entryId = nextId("entry")
        const entries = currentEntries.slice()
        entries.push({ id: entryId, path: normalizedPath,
            durationMs: durationMs })
        if (!commitPlaylist(index, Object.assign({}, playlists[index], {
                entries: entries
            })))
            return ""
        return entryId
    }

    function removeEntry(playlistId, entryId) {
        if (!loaded)
            return false
        const index = playlistIndex(playlistId)
        if (index < 0) {
            error = "Playlist does not exist"
            return false
        }
        const id = String(entryId || "").trim()
        const entries = (playlists[index].entries || [])
            .filter(entry => entry.id !== id)
        if (entries.length === playlists[index].entries.length) {
            error = "Playlist entry does not exist"
            return false
        }
        return commitPlaylist(index, Object.assign({}, playlists[index], {
            entries: entries
        }))
    }

    function updateEntry(playlistId, entryId, path, durationMs) {
        if (!loaded)
            return false
        const index = playlistIndex(playlistId)
        const normalizedPath = String(path || "").trim()
        if (index < 0 || normalizedPath.length === 0) {
            error = index < 0 ? "Playlist does not exist"
                : "Wallpaper path is required"
            return false
        }
        const entries = (playlists[index].entries || []).map(entry =>
            entry.id === entryId ? Object.assign({}, entry, {
                path: normalizedPath,
                durationMs: durationMs
            }) : entry)
        if (!entries.some(entry => entry.id === entryId)) {
            error = "Playlist entry does not exist"
            return false
        }
        return commitPlaylist(index, Object.assign({}, playlists[index], {
            entries: entries
        }))
    }

    function moveEntry(playlistId, entryId, targetIndex) {
        if (!loaded)
            return false
        const index = playlistIndex(playlistId)
        if (index < 0) {
            error = "Playlist does not exist"
            return false
        }
        const entries = (playlists[index].entries || []).slice()
        const sourceIndex = entries.findIndex(entry => entry.id === entryId)
        const destination = Math.floor(Number(targetIndex))
        if (sourceIndex < 0 || !Number.isFinite(destination)
                || destination < 0 || destination >= entries.length) {
            error = sourceIndex < 0 ? "Playlist entry does not exist"
                : "Playlist entry position is out of range"
            return false
        }
        if (sourceIndex === destination) {
            error = ""
            return true
        }
        const moved = entries.splice(sourceIndex, 1)[0]
        entries.splice(destination, 0, moved)
        return commitPlaylist(index, Object.assign({}, playlists[index], {
            entries: entries
        }))
    }

    function clear() {
        if (!loaded) {
            error = "Wallpaper playlists are still loading"
            return false
        }
        playlists = []
        resetValidation()
        error = ""
        markDirty()
        return true
    }

    function snapshot() {
        return {
            loaded: loaded,
            schemaVersion: data.schemaVersion,
            playlists: playlists,
            validation: validation,
            error: error
        }
    }

    function entryValidation(entry, duplicate) {
        const path = String(entry?.path || "")
        if (duplicate)
            return { status: "duplicate", error: "Duplicate path in playlist" }
        const media = WallpaperProbeService.recordFor(path)
        if (WallpaperProbeService.activePath === path
                || WallpaperProbeService.queue.indexOf(path) >= 0
                || media.state === "unknown" || media.state === "queued"
                || media.state === "probing" || media.state === "cancelled")
            return { status: "pending", error: "" }
        if (media.state === "failed") {
            const unavailable = String(media.error || "")
                === "Wallpaper source is unavailable"
            return { status: unavailable ? "missing" : "failed",
                error: String(media.error || "Media validation failed") }
        }
        if (media.state !== "ready"
                || !WallpaperRenderSupportService.supported(media))
            return { status: "unsupported",
                error: String(media.error || "No supported renderer") }
        return { status: "valid", error: "", kind: media.kind,
            backend: WallpaperRenderSupportService.rendererFor(media) }
    }

    function rebuildValidation() {
        validationUpdateScheduled = false
        const report = {
            state: "ready", playlists: [], total: 0, valid: 0,
            pending: 0, missing: 0, unsupported: 0, duplicate: 0, failed: 0
        }
        for (const playlist of playlists) {
            const paths = ({})
            const entries = []
            for (const entry of playlist.entries || []) {
                const path = String(entry.path || "")
                const result = entryValidation(entry, Boolean(paths[path]))
                paths[path] = true
                report.total += 1
                report[result.status] += 1
                entries.push(Object.assign({}, entry, result))
            }
            report.playlists.push({
                id: playlist.id,
                name: playlist.name,
                entries: entries
            })
        }
        if (report.pending > 0)
            report.state = "validating"
        validation = report
        validationActive = report.pending > 0
    }

    function validate() {
        if (!loaded) {
            error = "Wallpaper playlists are still loading"
            return false
        }
        validationActive = false
        const queued = ({})
        for (const playlist of playlists) {
            for (const entry of playlist.entries || []) {
                const path = String(entry.path || "")
                if (queued[path])
                    continue
                queued[path] = true
                WallpaperProbeService.enqueue(path)
            }
        }
        validationActive = true
        rebuildValidation()
        return true
    }

    function scheduleValidationUpdate() {
        if (!validationActive || validationUpdateScheduled)
            return
        validationUpdateScheduled = true
        Qt.callLater(rebuildValidation)
    }

    Connections {
        target: WallpaperProbeService
        function onRecordsChanged() { root.scheduleValidationUpdate() }
        function onActivePathChanged() { root.scheduleValidationUpdate() }
        function onQueueChanged() { root.scheduleValidationUpdate() }
    }

    function markDirty() {
        if (loaded)
            saveTimer.restart()
    }

    function validateLoadedData() {
        const normalized = normalizedDocument({ playlists: playlists })
        if (data.schemaVersion !== normalized.schemaVersion
                || JSON.stringify(playlists) !== JSON.stringify(
                    normalized.playlists)) {
            data.schemaVersion = normalized.schemaVersion
            playlists = normalized.playlists
            markDirty()
        }
    }

    Timer {
        id: saveTimer
        interval: 180
        onTriggered: stateFile.writeAdapter()
    }

    Timer {
        id: reloadTimer
        interval: 60
        onTriggered: stateFile.reload()
    }

    FileView {
        id: stateFile
        path: Quickshell.statePath("wallpaper-playlists.json")
        watchChanges: true
        printErrors: false
        onAdapterUpdated: if (root.loaded) saveTimer.restart()
        onFileChanged: reloadTimer.restart()
        onLoaded: {
            root.loaded = true
            try {
                JSON.parse(text())
                root.error = ""
                root.validateLoadedData()
            } catch (exception) {
                root.error = "Wallpaper playlist JSON is invalid"
            }
        }
        onLoadFailed: failure => {
            root.loaded = true
            root.error = failure === FileViewError.FileNotFound ? ""
                : "Wallpaper playlists could not be loaded"
        }

        JsonAdapter {
            id: data
            property int schemaVersion: 1
            property var playlists: []
        }
    }
}
