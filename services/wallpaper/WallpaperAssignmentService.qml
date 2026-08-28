pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services.wallpaper

Singleton {
    id: root

    property alias globalWallpaper: data.globalWallpaper
    property alias screenWallpapers: data.screenWallpapers
    property bool loaded: false
    property string error: ""

    function normalizePath(path) {
        return String(path || "").trim()
    }

    function validWallpaper(path) {
        const normalized = normalizePath(path)
        return normalized.length > 0
            && WallpaperCatalogService.isSupported(normalized)
            && !WallpaperCatalogService.isExcluded(normalized)
    }

    function wallpaperForScreen(screenName) {
        const name = String(screenName || "")
        const assigned = screenWallpapers[name]
        return assigned && String(assigned).length > 0
            ? String(assigned) : globalWallpaper
    }

    function setGlobal(path) {
        const normalized = normalizePath(path)
        if (!validWallpaper(normalized)) {
            error = "Unsupported wallpaper path"
            return false
        }
        error = ""
        screenWallpapers = ({})
        globalWallpaper = normalized
        return true
    }

    function clearGlobal() {
        error = ""
        globalWallpaper = ""
    }

    function setForScreen(screenName, path) {
        const name = String(screenName || "").trim()
        const normalized = normalizePath(path)
        if (name.length === 0 || !validWallpaper(normalized)) {
            error = name.length === 0
                ? "A screen name is required" : "Unsupported wallpaper path"
            return false
        }

        const updated = ({})
        for (const key in screenWallpapers)
            updated[key] = screenWallpapers[key]
        updated[name] = normalized
        error = ""
        screenWallpapers = updated
        return true
    }

    function clearScreen(screenName) {
        const name = String(screenName || "").trim()
        if (name.length === 0)
            return
        const updated = ({})
        for (const key in screenWallpapers) {
            if (key !== name)
                updated[key] = screenWallpapers[key]
        }
        error = ""
        screenWallpapers = updated
    }

    function snapshot() {
        return {
            loaded: loaded,
            global: globalWallpaper,
            screens: screenWallpapers,
            error: error
        }
    }

    Timer {
        id: saveTimer
        interval: 180
        onTriggered: stateFile.writeAdapter()
    }

    FileView {
        id: stateFile
        path: Quickshell.statePath("wallpaper-assignments.json")
        watchChanges: true
        printErrors: false
        onAdapterUpdated: if (root.loaded) saveTimer.restart()
        onFileChanged: reload()
        onLoaded: {
            root.loaded = true
            root.error = ""
        }
        onLoadFailed: failure => {
            if (failure === FileViewError.FileNotFound) {
                root.loaded = true
            } else {
                root.error = "Wallpaper assignments could not be loaded"
            }
        }

        JsonAdapter {
            id: data
            property string globalWallpaper: ""
            property var screenWallpapers: ({})
        }
    }
}
