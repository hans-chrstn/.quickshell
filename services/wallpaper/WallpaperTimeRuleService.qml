pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "WallpaperTimeRuleModel.js" as RuleModel

Singleton {
    id: root

    property alias rules: data.rules
    property bool loaded: false
    property string error: ""
    property int idSequence: 0
    property bool reconcileScheduled: false
    readonly property int maximumRules: RuleModel.maximumRules

    function normalizedDocument(value) {
        return RuleModel.normalizeDocument(value)
    }

    function playlistExists(playlistId) {
        const id = String(playlistId || "").trim()
        return id.length > 0 && WallpaperPlaylistService.playlists
            .some(playlist => playlist.id === id)
    }

    function readyToMutate() {
        if (loaded && WallpaperPlaylistService.loaded)
            return true
        error = "Wallpaper time rules are still loading"
        return false
    }

    function parseDays(value) {
        if (Array.isArray(value))
            return value
        const text = String(value || "").trim()
        return text.length > 0 ? text.split(",") : []
    }

    function validateReferences(values) {
        for (const rule of values || []) {
            if (!playlistExists(rule.playlistId)) {
                error = "Time rule playlist does not exist"
                return false
            }
        }
        return true
    }

    function commit(values) {
        const normalized = normalizedDocument({ rules: values })
        if (!validateReferences(normalized.rules))
            return false
        data.schemaVersion = normalized.schemaVersion
        rules = normalized.rules
        error = ""
        markDirty()
        return true
    }

    function replaceDocument(value) {
        if (!readyToMutate())
            return false
        if (!value || typeof value !== "object"
                || !Array.isArray(value.rules)) {
            error = "Time rule document must contain a rules array"
            return false
        }
        return commit(value.rules)
    }

    function replaceJson(value) {
        try {
            return replaceDocument(JSON.parse(String(value || "")))
        } catch (exception) {
            error = "Wallpaper time rule JSON is invalid"
            return false
        }
    }

    function createRule(name, playlistId, screenName, dayValues,
            startMinute, endMinute, priority) {
        if (!readyToMutate())
            return ""
        if (rules.length >= maximumRules) {
            error = "Wallpaper time rule limit reached"
            return ""
        }
        const playlist = String(playlistId || "").trim()
        if (!playlistExists(playlist)) {
            error = "Time rule playlist does not exist"
            return ""
        }
        idSequence += 1
        const id = "rule-" + Date.now().toString(36)
            + "-" + idSequence.toString(36)
        const updated = rules.slice()
        updated.push({
            id: id,
            name: String(name || ""),
            enabled: true,
            playlistId: playlist,
            screenName: String(screenName || ""),
            days: parseDays(dayValues),
            startMinute: startMinute,
            endMinute: endMinute,
            priority: priority
        })
        return commit(updated) ? id : ""
    }

    function updateRule(ruleId, name, playlistId, screenName, dayValues,
            startMinute, endMinute, priority, enabled) {
        if (!readyToMutate())
            return false
        const id = String(ruleId || "").trim()
        const playlist = String(playlistId || "").trim()
        const index = rules.findIndex(rule => rule.id === id)
        if (index < 0 || !playlistExists(playlist)) {
            error = index < 0 ? "Wallpaper time rule does not exist"
                : "Time rule playlist does not exist"
            return false
        }
        const updated = rules.slice()
        updated[index] = {
            id: id,
            name: String(name || ""),
            enabled: Boolean(enabled),
            playlistId: playlist,
            screenName: String(screenName || ""),
            days: parseDays(dayValues),
            startMinute: startMinute,
            endMinute: endMinute,
            priority: priority
        }
        return commit(updated)
    }

    function setEnabled(ruleId, enabled) {
        const id = String(ruleId || "").trim()
        const rule = rules.find(item => item.id === id)
        if (!readyToMutate() || !rule) {
            if (loaded && !rule)
                error = "Wallpaper time rule does not exist"
            return false
        }
        return updateRule(id, rule.name, rule.playlistId,
            rule.screenName, rule.days, rule.startMinute,
            rule.endMinute, rule.priority, enabled)
    }

    function removeRule(ruleId) {
        if (!readyToMutate())
            return false
        const id = String(ruleId || "").trim()
        const updated = rules.filter(rule => rule.id !== id)
        if (updated.length === rules.length) {
            error = "Wallpaper time rule does not exist"
            return false
        }
        return commit(updated)
    }

    function clear() {
        if (!readyToMutate())
            return false
        return commit([])
    }

    function snapshot() {
        return {
            loaded: loaded,
            schemaVersion: data.schemaVersion,
            maximumRules: maximumRules,
            rules: rules.map(rule => Object.assign({}, rule, {
                days: (rule.days || []).slice()
            })),
            error: error
        }
    }

    function markDirty() {
        if (loaded)
            saveTimer.restart()
    }

    function reconcile() {
        reconcileScheduled = false
        if (!loaded || !WallpaperPlaylistService.loaded)
            return
        const retained = rules.filter(rule => playlistExists(rule.playlistId))
        const normalized = normalizedDocument({ rules: retained })
        if (data.schemaVersion !== normalized.schemaVersion
                || JSON.stringify(rules) !== JSON.stringify(normalized.rules)) {
            data.schemaVersion = normalized.schemaVersion
            rules = normalized.rules
            markDirty()
        }
    }

    function scheduleReconcile() {
        if (reconcileScheduled)
            return
        reconcileScheduled = true
        Qt.callLater(reconcile)
    }

    Connections {
        target: WallpaperPlaylistService
        function onLoadedChanged() { root.scheduleReconcile() }
        function onPlaylistsChanged() { root.scheduleReconcile() }
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
        path: Quickshell.statePath("wallpaper-time-rules.json")
        watchChanges: true
        printErrors: false
        onAdapterUpdated: if (root.loaded) saveTimer.restart()
        onFileChanged: reloadTimer.restart()
        onLoaded: {
            root.loaded = true
            try {
                JSON.parse(text())
                root.error = ""
                root.scheduleReconcile()
            } catch (exception) {
                root.error = "Wallpaper time rule JSON is invalid"
            }
        }
        onLoadFailed: failure => {
            root.loaded = true
            root.error = failure === FileViewError.FileNotFound ? ""
                : "Wallpaper time rules could not be loaded"
            root.scheduleReconcile()
        }

        JsonAdapter {
            id: data
            property int schemaVersion: 1
            property var rules: []
        }
    }
}
