pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property alias revealDuration: data.revealDuration
    property alias resizeDuration: data.resizeDuration
    property alias contentRevealDuration: data.contentRevealDuration
    property alias attentionExpandDelay: data.attentionExpandDelay
    property alias moduleCloseDuration: data.moduleCloseDuration
    property alias expandDelay: data.expandDelay
    property alias hideDelay: data.hideDelay
    property alias islandWing: data.islandWing
    property alias islandCollapsedWidth: data.islandCollapsedWidth
    property alias islandWidthPercent: data.islandWidthPercent
    property alias islandHeightPercent: data.islandHeightPercent
    property alias islandBodyRadius: data.islandBodyRadius
    property alias enableBlur: data.enableBlur
    property alias experimentalFloatingWallpaperSuspension:
        data.experimentalFloatingWallpaperSuspension
    property alias experimentalPauseWallpaperOnBattery:
        data.experimentalPauseWallpaperOnBattery
    property alias allowWallpaperOptimization:
        data.allowWallpaperOptimization
    property alias optimizeWallpaperResolution:
        data.optimizeWallpaperResolution
    property alias optimizeWallpaperResolutionScale:
        data.optimizeWallpaperResolutionScale
    property alias optimizeWallpaperFrameRate:
        data.optimizeWallpaperFrameRate
    property alias optimizeWallpaperFrameRateLimit:
        data.optimizeWallpaperFrameRateLimit
    property alias optimizeWallpaperBitRate:
        data.optimizeWallpaperBitRate
    property alias automaticWallpaperCacheCleanup:
        data.automaticWallpaperCacheCleanup
    property alias adaptiveLifecycleEnabled: data.adaptiveLifecycleEnabled
    property alias wallpaperDirectories: data.wallpaperDirectories

    property bool loaded: false
    property string error: ""

    readonly property var settingSchema: ({
        revealDuration: { type: "int", minimum: 120, maximum: 600 },
        resizeDuration: { type: "int", minimum: 200, maximum: 900 },
        contentRevealDuration: { type: "int", minimum: 80, maximum: 400 },
        attentionExpandDelay: { type: "int", minimum: 0, maximum: 500 },
        moduleCloseDuration: { type: "int", minimum: 180, maximum: 800 },
        expandDelay: { type: "int", minimum: 0, maximum: 1000 },
        hideDelay: { type: "int", minimum: 300, maximum: 3000 },
        islandWing: { type: "int", minimum: 0, maximum: 40 },
        islandCollapsedWidth: { type: "int", minimum: 100, maximum: 300 },
        islandWidthPercent: { type: "int", minimum: 90, maximum: 125 },
        islandHeightPercent: { type: "int", minimum: 90, maximum: 125 },
        islandBodyRadius: { type: "int", minimum: 0, maximum: 40 },
        enableBlur: { type: "bool" },
        experimentalFloatingWallpaperSuspension: { type: "bool" },
        experimentalPauseWallpaperOnBattery: { type: "bool" },
        allowWallpaperOptimization: { type: "bool" },
        optimizeWallpaperResolution: { type: "bool" },
        optimizeWallpaperResolutionScale: {
            type: "enum", values: [1, 1.25, 1.5], defaultValue: 1
        },
        optimizeWallpaperFrameRate: { type: "bool" },
        optimizeWallpaperFrameRateLimit: {
            type: "enum", values: [15, 24, 30], defaultValue: 30
        },
        optimizeWallpaperBitRate: { type: "bool" },
        automaticWallpaperCacheCleanup: { type: "bool" },
        adaptiveLifecycleEnabled: { type: "bool" }
    })

    function normalizedSetting(key, value) {
        const definition = settingSchema[key]
        if (!definition)
            return undefined
        if (definition.type === "bool") {
            if (typeof value === "string")
                return value.trim().toLowerCase() === "true"
            return Boolean(value)
        }
        if (definition.type === "enum") {
            const numeric = Number(value)
            return definition.values.indexOf(numeric) >= 0
                ? numeric : definition.defaultValue
        }
        const numeric = Number(value)
        if (!Number.isFinite(numeric))
            return data[key]
        return Math.round(Math.max(definition.minimum,
            Math.min(definition.maximum, numeric)))
    }

    function setSetting(key, value) {
        const definition = settingSchema[key]
        if (definition?.type === "enum"
                && definition.values.indexOf(Number(value)) < 0)
            return false
        const normalized = normalizedSetting(key, value)
        if (normalized === undefined)
            return false
        if (data[key] === normalized)
            return true
        data[key] = normalized
        markDirty()
        return true
    }

    function setSettings(values) {
        let changed = false
        for (const key in values || {}) {
            const normalized = normalizedSetting(key, values[key])
            if (normalized === undefined || data[key] === normalized)
                continue
            data[key] = normalized
            changed = true
        }
        if (changed)
            markDirty()
    }

    function normalizedDirectories(values) {
        const result = []
        const seen = ({})
        for (let raw of values || []) {
            let path = String(raw || "").trim()
            if (path.startsWith("file://"))
                path = decodeURIComponent(path.slice(7))
            path = path.replace(/\/+$/, "") || "/"
            if (path.length === 0 || seen[path])
                continue
            seen[path] = true
            result.push(path)
        }
        return result
    }

    function setWallpaperDirectories(values) {
        const normalized = normalizedDirectories(values)
        if (JSON.stringify(normalized) === JSON.stringify(wallpaperDirectories))
            return
        wallpaperDirectories = normalized
        markDirty()
    }

    function snapshot() {
        const settings = ({})
        for (const key in settingSchema)
            settings[key] = data[key]
        return {
            loaded: loaded,
            schemaVersion: data.schemaVersion,
            settings: settings,
            wallpaperDirectories: wallpaperDirectories,
            error: error
        }
    }

    function markDirty() {
        if (loaded)
            saveTimer.restart()
    }

    function validateLoadedData() {
        let changed = false
        for (const key in settingSchema) {
            const normalized = normalizedSetting(key, data[key])
            if (data[key] !== normalized) {
                data[key] = normalized
                changed = true
            }
        }
        const directories = normalizedDirectories(wallpaperDirectories)
        if (JSON.stringify(directories) !== JSON.stringify(wallpaperDirectories)) {
            wallpaperDirectories = directories
            changed = true
        }
        if (data.schemaVersion !== 1) {
            data.schemaVersion = 1
            changed = true
        }
        if (changed)
            markDirty()
    }

    Timer {
        id: saveTimer
        interval: 180
        onTriggered: configFile.writeAdapter()
    }

    Timer {
        id: reloadTimer
        interval: 60
        onTriggered: configFile.reload()
    }

    FileView {
        id: configFile
        path: Quickshell.statePath("settings.json")
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
                root.error = "Configuration JSON is invalid; defaults are active"
            }
        }
        onLoadFailed: failure => {
            root.loaded = true
            if (failure === FileViewError.FileNotFound)
                root.error = ""
            else
                root.error = "Configuration could not be loaded; defaults are active"
        }

        JsonAdapter {
            id: data
            property int schemaVersion: 1
            property int revealDuration: 300
            property int resizeDuration: 520
            property int contentRevealDuration: 180
            property int attentionExpandDelay: 170
            property int moduleCloseDuration: 440
            property int expandDelay: 420
            property int hideDelay: 1200
            property int islandWing: 16
            property int islandCollapsedWidth: 184
            property int islandWidthPercent: 100
            property int islandHeightPercent: 100
            property int islandBodyRadius: 20
            property bool enableBlur: true
            property bool experimentalFloatingWallpaperSuspension: false
            property bool experimentalPauseWallpaperOnBattery: false
            property bool allowWallpaperOptimization: true
            property bool optimizeWallpaperResolution: true
            property real optimizeWallpaperResolutionScale: 1
            property bool optimizeWallpaperFrameRate: true
            property int optimizeWallpaperFrameRateLimit: 30
            property bool optimizeWallpaperBitRate: true
            property bool automaticWallpaperCacheCleanup: false
            property bool adaptiveLifecycleEnabled: true
            property var wallpaperDirectories: []
        }
    }
}
