pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services.wallpaper

Singleton {
    id: root

    property alias globalPlaylistId: data.globalPlaylistId
    property alias screenPlaylistIds: data.screenPlaylistIds
    property bool loaded: false
    property string error: ""
    property bool reconcileScheduled: false
    readonly property int maximumScreenTargets: 32

    function normalizedId(value) {
        return String(value || "").trim().slice(0, 96)
    }

    function playlistExists(value) {
        const id = normalizedId(value)
        return id.length > 0 && WallpaperPlaylistService.playlists
            .some(playlist => playlist.id === id)
    }

    function readyToMutate() {
        if (loaded && WallpaperPlaylistService.loaded)
            return true
        error = "Wallpaper playlist targets are still loading"
        return false
    }

    function playlistForScreen(screenName) {
        const name = String(screenName || "").trim().slice(0, 128)
        const selected = normalizedId(screenPlaylistIds[name])
        return selected.length > 0 ? selected : globalPlaylistId
    }

    function setGlobal(playlistId) {
        if (!readyToMutate())
            return false
        const id = normalizedId(playlistId)
        if (!playlistExists(id)) {
            error = "Playlist target does not exist"
            return false
        }
        screenPlaylistIds = ({})
        globalPlaylistId = id
        error = ""
        return true
    }

    function clearGlobal() {
        if (!readyToMutate())
            return false
        globalPlaylistId = ""
        error = ""
        return true
    }

    function setForScreen(screenName, playlistId) {
        if (!readyToMutate())
            return false
        const name = String(screenName || "").trim().slice(0, 128)
        const id = normalizedId(playlistId)
        if (name.length === 0 || !playlistExists(id)) {
            error = name.length === 0 ? "A screen name is required"
                : "Playlist target does not exist"
            return false
        }
        const updated = Object.assign({}, screenPlaylistIds)
        if (updated[name] === undefined
                && Object.keys(updated).length >= maximumScreenTargets) {
            error = "Playlist screen-target limit reached"
            return false
        }
        updated[name] = id
        screenPlaylistIds = updated
        error = ""
        return true
    }

    function clearScreen(screenName) {
        if (!readyToMutate())
            return false
        const name = String(screenName || "").trim().slice(0, 128)
        if (name.length === 0)
            return false
        const updated = ({})
        for (const key in screenPlaylistIds) {
            if (key !== name)
                updated[key] = screenPlaylistIds[key]
        }
        screenPlaylistIds = updated
        error = ""
        return true
    }

    function reconcile() {
        reconcileScheduled = false
        if (!loaded || !WallpaperPlaylistService.loaded)
            return
        let changed = false
        if (globalPlaylistId.length > 0
                && !playlistExists(globalPlaylistId)) {
            globalPlaylistId = ""
            changed = true
        }
        const updated = ({})
        let retainedTargets = 0
        for (const rawScreenName in screenPlaylistIds) {
            if (retainedTargets >= maximumScreenTargets) {
                changed = true
                continue
            }
            const screenName = String(rawScreenName || "")
                .trim().slice(0, 128)
            const id = normalizedId(screenPlaylistIds[rawScreenName])
            if (screenName.length > 0 && playlistExists(id)) {
                updated[screenName] = id
                retainedTargets += 1
                if (screenName !== rawScreenName)
                    changed = true
            } else {
                changed = true
            }
        }
        if (changed)
            screenPlaylistIds = updated
    }

    function scheduleReconcile() {
        if (reconcileScheduled)
            return
        reconcileScheduled = true
        Qt.callLater(reconcile)
    }

    function snapshot() {
        return {
            loaded: loaded,
            global: globalPlaylistId,
            screens: Object.assign({}, screenPlaylistIds),
            error: error
        }
    }

    Timer {
        id: saveTimer
        interval: 180
        onTriggered: stateFile.writeAdapter()
    }

    Connections {
        target: WallpaperPlaylistService
        function onLoadedChanged() { root.scheduleReconcile() }
        function onPlaylistsChanged() { root.scheduleReconcile() }
    }

    FileView {
        id: stateFile
        path: Quickshell.statePath("wallpaper-playlist-targets.json")
        watchChanges: true
        printErrors: false
        onAdapterUpdated: if (root.loaded) saveTimer.restart()
        onFileChanged: reload()
        onLoaded: {
            root.loaded = true
            try {
                JSON.parse(text())
                root.error = ""
                root.scheduleReconcile()
            } catch (exception) {
                root.error = "Wallpaper playlist target JSON is invalid"
            }
        }
        onLoadFailed: failure => {
            root.loaded = true
            root.error = failure === FileViewError.FileNotFound ? ""
                : "Wallpaper playlist targets could not be loaded"
            root.scheduleReconcile()
        }

        JsonAdapter {
            id: data
            property string globalPlaylistId: ""
            property var screenPlaylistIds: ({})
        }
    }
}
