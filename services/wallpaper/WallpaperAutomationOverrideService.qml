pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "WallpaperAutomationOverride.js" as Override

Singleton {
    id: root

    property alias globalSuppressed: data.globalSuppressed
    property alias screenSuppressions: data.screenSuppressions
    property bool loaded: false
    property string error: ""
    readonly property int maximumScreens: Override.maximumScreens

    function document() {
        return {
            global: globalSuppressed,
            screens: screenSuppressions
        }
    }

    function commit(value) {
        const normalized = Override.normalize(value)
        globalSuppressed = normalized.global
        screenSuppressions = normalized.screens
        error = ""
        if (loaded)
            saveTimer.restart()
        return true
    }

    function ready() {
        if (loaded)
            return true
        error = "Wallpaper automation overrides are still loading"
        return false
    }

    function suppressGlobal() {
        return ready() && commit(Override.suppressGlobal(document()))
    }

    function suppressScreen(screenName) {
        if (!ready())
            return false
        const name = Override.screenName(screenName)
        if (name.length === 0) {
            error = "A screen name is required"
            return false
        }
        if (globalSuppressed) {
            error = "Global manual override is already active"
            return false
        }
        if (screenSuppressions[name] !== true
                && Object.keys(screenSuppressions).length >= maximumScreens) {
            error = "Wallpaper automation override limit reached"
            return false
        }
        return commit(Override.suppressScreen(document(), name))
    }

    function resumeAll() {
        return ready() && commit(Override.resumeAll(document()))
    }

    function resumeScreen(screenName) {
        if (!ready())
            return false
        const name = Override.screenName(screenName)
        if (name.length === 0) {
            error = "A screen name is required"
            return false
        }
        if (globalSuppressed) {
            error = "Resume global automation before a single output"
            return false
        }
        return commit(Override.resumeScreen(document(), name))
    }

    function suppressedForScreen(screenName) {
        return loaded && Override.suppressed(document(), screenName)
    }

    function snapshot() {
        return {
            loaded: loaded,
            schemaVersion: data.schemaVersion,
            global: globalSuppressed,
            screens: Object.assign({}, screenSuppressions),
            error: error
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
        path: Quickshell.statePath("wallpaper-automation-overrides.json")
        watchChanges: true
        printErrors: false
        onAdapterUpdated: if (root.loaded) saveTimer.restart()
        onFileChanged: reloadTimer.restart()
        onLoaded: {
            root.loaded = true
            try {
                JSON.parse(text())
                root.commit(root.document())
            } catch (exception) {
                root.error = "Wallpaper automation override JSON is invalid"
            }
        }
        onLoadFailed: failure => {
            root.loaded = true
            root.error = failure === FileViewError.FileNotFound ? ""
                : "Wallpaper automation overrides could not be loaded"
        }

        JsonAdapter {
            id: data
            property int schemaVersion: 1
            property bool globalSuppressed: false
            property var screenSuppressions: ({})
        }
    }
}
