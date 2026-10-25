pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../../core/Base64.js" as Base64
import "WallpaperHookModel.js" as HookModel

Singleton {
    id: root

    property alias hooks: data.hooks
    property bool loaded: false
    property string error: ""
    property int idSequence: 0
    readonly property int maximumHooks: HookModel.maximumHooks

    function readyToMutate() {
        if (loaded)
            return true
        error = "Wallpaper hooks are still loading"
        return false
    }

    function parseArguments(value) {
        if (Array.isArray(value))
            return value
        let text = String(value || "").trim()
        if (text.length === 0)
            return []
        try {
            if (text.startsWith("b64_"))
                text = Base64.decode(text.slice(4))
            else if (text.startsWith("base64:"))
                text = Base64.decode(text.slice(7))
            if (text === null)
                throw new Error("Invalid Base64")
            const parsed = JSON.parse(text)
            if (Array.isArray(parsed))
                return parsed
        } catch (exception) {
        }
        error = "Wallpaper hook arguments must be a JSON array"
        return null
    }

    function commit(values) {
        const normalized = HookModel.normalizeDocument({ hooks: values })
        data.schemaVersion = normalized.schemaVersion
        hooks = normalized.hooks
        error = ""
        markDirty()
        return true
    }

    function replaceDocument(value) {
        if (!readyToMutate())
            return false
        if (!value || typeof value !== "object"
                || !Array.isArray(value.hooks)) {
            error = "Wallpaper hook document must contain a hooks array"
            return false
        }
        const version = Math.floor(Number(value.schemaVersion)
            || HookModel.schemaVersion)
        if (version > HookModel.schemaVersion) {
            error = "Wallpaper hook document uses a newer schema"
            return false
        }
        return commit(value.hooks)
    }

    function replaceJson(value) {
        try {
            let text = String(value || "").trim()
            if (text.startsWith("b64_"))
                text = Base64.decode(text.slice(4))
            else if (text.startsWith("base64:"))
                text = Base64.decode(text.slice(7))
            if (text === null)
                throw new Error("Invalid Base64")
            return replaceDocument(JSON.parse(text))
        } catch (exception) {
            error = "Wallpaper hook JSON is invalid"
            return false
        }
    }

    function normalizedCandidate(value) {
        const normalized = HookModel.normalizeDocument({ hooks: [value] })
        return normalized.hooks.length === 1 ? normalized.hooks[0] : null
    }

    function createHook(name, phase, executable, argumentJson, screenName,
            timeoutMs, priority) {
        if (!readyToMutate())
            return ""
        if (hooks.length >= maximumHooks) {
            error = "Wallpaper hook limit reached"
            return ""
        }
        const values = parseArguments(argumentJson)
        if (values === null)
            return ""
        idSequence += 1
        const id = "hook-" + Date.now().toString(36)
            + "-" + idSequence.toString(36)
        const candidate = normalizedCandidate({
            id: id,
            name: name,
            enabled: false,
            phase: phase,
            executable: executable,
            arguments: values,
            screenName: screenName,
            timeoutMs: timeoutMs,
            priority: priority
        })
        if (!candidate) {
            error = "Wallpaper hook requires a valid phase and absolute executable"
            return ""
        }
        const updated = hooks.slice()
        updated.push(candidate)
        return commit(updated) ? candidate.id : ""
    }

    function updateHook(hookId, name, phase, executable, argumentJson,
            screenName, timeoutMs, priority, enabled) {
        if (!readyToMutate())
            return false
        const id = String(hookId || "").trim()
        const index = hooks.findIndex(hook => hook.id === id)
        if (index < 0) {
            error = "Wallpaper hook does not exist"
            return false
        }
        const values = parseArguments(argumentJson)
        if (values === null)
            return false
        const candidate = normalizedCandidate({
            id: id,
            name: name,
            enabled: Boolean(enabled),
            phase: phase,
            executable: executable,
            arguments: values,
            screenName: screenName,
            timeoutMs: timeoutMs,
            priority: priority
        })
        if (!candidate) {
            error = "Wallpaper hook requires a valid phase and absolute executable"
            return false
        }
        const updated = hooks.slice()
        updated[index] = candidate
        return commit(updated)
    }

    function setEnabled(hookId, enabled) {
        if (!readyToMutate())
            return false
        const id = String(hookId || "").trim()
        const hook = hooks.find(item => item.id === id)
        if (!hook) {
            error = "Wallpaper hook does not exist"
            return false
        }
        return updateHook(id, hook.name, hook.phase, hook.executable,
            JSON.stringify(hook.arguments), hook.screenName,
            hook.timeoutMs, hook.priority, enabled)
    }

    function removeHook(hookId) {
        if (!readyToMutate())
            return false
        const id = String(hookId || "").trim()
        const updated = hooks.filter(hook => hook.id !== id)
        if (updated.length === hooks.length) {
            error = "Wallpaper hook does not exist"
            return false
        }
        return commit(updated)
    }

    function clear() {
        return readyToMutate() && commit([])
    }

    function snapshot() {
        return {
            loaded: loaded,
            schemaVersion: data.schemaVersion,
            maximumHooks: maximumHooks,
            hooks: hooks.map(hook => Object.assign({}, hook, {
                arguments: (hook.arguments || []).slice()
            })),
            error: error
        }
    }

    function markDirty() {
        if (loaded)
            saveTimer.restart()
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
        path: Quickshell.statePath("wallpaper-hooks.json")
        watchChanges: true
        printErrors: false
        onAdapterUpdated: if (root.loaded) saveTimer.restart()
        onFileChanged: reloadTimer.restart()
        onLoaded: {
            root.loaded = true
            try {
                const document = JSON.parse(text())
                if (Number(document.schemaVersion) > HookModel.schemaVersion) {
                    root.error = "Wallpaper hook document uses a newer schema"
                    return
                }
                const normalized = HookModel.normalizeDocument(document)
                root.error = ""
                if (data.schemaVersion !== normalized.schemaVersion
                        || JSON.stringify(root.hooks)
                            !== JSON.stringify(normalized.hooks))
                    root.commit(normalized.hooks)
            } catch (exception) {
                root.error = "Wallpaper hook JSON is invalid"
            }
        }
        onLoadFailed: failure => {
            root.loaded = true
            root.error = failure === FileViewError.FileNotFound ? ""
                : "Wallpaper hooks could not be loaded"
        }

        JsonAdapter {
            id: data
            property int schemaVersion: 1
            property var hooks: []
        }
    }
}
