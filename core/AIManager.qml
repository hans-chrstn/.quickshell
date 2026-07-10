pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool isLoading: false
    property bool isConfigured: false

    property ListModel messages: ListModel { }
    property ListModel attachments: ListModel { }
    property ListModel sessions: ListModel { }
    property int activeSessionIndex: -1
    property bool showingSessions: false
    property string view: "chat"

    readonly property string configCachePath: Quickshell.cachePath("ai_config")
    readonly property string sessionsCachePath: ""

    property string _apiUrl: ""
    property string _model: ""
    property string _apiKey: ""
    property string configuredUrl: ""
    property string configuredModel: ""
    property string configuredName: ""

    FileView {
        id: configCacheFile
        path: root.configCachePath
        onLoaded: root.loadConfigFromCache()
    }

    FileView {
        id: sessionsCacheFile
        path: Quickshell.cachePath("ai_sessions")
        onLoaded: root.loadSessionsFromCache()
    }

    property var _allSessionsStore: ({})

    Timer {
        interval: 100
        running: true
        repeat: false
        onTriggered: {
            root.loadConfigFromCache()
            root.loadSessionsFromCache()
        }
    }

    function loadConfigFromCache() {
        let raw = configCacheFile.text().trim()
        if (!raw) return
        try {
            let data = JSON.parse(raw)
            let list = Array.isArray(data) ? data : [data]
            presets.clear()
            for (let i = 0; i < list.length; i++) {
                let p = list[i]
                if (p.url && p.key && (p.model || p.modelName)) {
                    presets.append({
                        name: p.name || "Preset " + (i + 1),
                        url: p.url,
                        modelName: p.model || p.modelName || "",
                        key: p.key
                    })
                }
            }
            if (presets.count > 0) {
                root.activatePreset(0)
            }
        } catch (e) {}
    }

    function _presetKey() {
        return String(activePresetIndex >= 0 ? activePresetIndex : 0)
    }

    function _loadSessionsFromStore() {
        let key = root._presetKey()
        let list = root._allSessionsStore[key] || []
        if (!Array.isArray(list)) list = []
        sessions.clear()
        for (let i = 0; i < list.length; i++) {
            let s = list[i]
            sessions.append({
                name: s.name || "Chat " + (i + 1),
                date: s.date || ""
            })
        }
    }

    function loadSessionsFromCache() {
        let raw = sessionsCacheFile.text().trim()
        if (!raw) return
        try {
            let parsed = JSON.parse(raw)
            if (Array.isArray(parsed)) {
                root._allSessionsStore = { "0": parsed }
            } else {
                root._allSessionsStore = parsed || {}
            }
            root._loadSessionsFromStore()
        } catch (e) {}
    }

    function saveSessionsToCache() {
        let data = {}
        for (let key in root._allSessionsStore) {
            let list = root._allSessionsStore[key]
            if (!Array.isArray(list)) list = []
            let cleanList = []
            for (let i = 0; i < list.length; i++) {
                let s = list[i]
                cleanList.push({
                    name: s.name || "",
                    date: s.date || "",
                    store: s.store || []
                })
            }
            data[key] = cleanList
        }
        sessionsCacheFile.setText(JSON.stringify(data, null, 2))
    }

    function saveActiveSession() {
        if (activeSessionIndex < 0 || activeSessionIndex >= sessions.count) return
        let s = sessions.get(activeSessionIndex)
        let msgs = []
        for (let i = 0; i < messages.count; i++) {
            let m = messages.get(i)
            msgs.push({ role: m.role, content: m.content })
        }
        let key = root._presetKey()
        let list = root._allSessionsStore[key] || []
        if (!Array.isArray(list)) list = []
        list[activeSessionIndex] = { name: s.name, date: s.date, store: msgs }
        root._allSessionsStore[key] = list
        saveSessionsToCache()
    }

    function newSession() {
        let now = new Date()
        let dateStr = now.getFullYear() + "-" +
                      String(now.getMonth() + 1).padStart(2, "0") + "-" +
                      String(now.getDate()).padStart(2, "0") + " " +
                      String(now.getHours()).padStart(2, "0") + ":" +
                      String(now.getMinutes()).padStart(2, "0")
        let name = "Chat " + dateStr

        let key = root._presetKey()
        let list = root._allSessionsStore[key] || []
        if (!Array.isArray(list)) list = []
        list.unshift({ name: name, date: dateStr, store: [] })
        root._allSessionsStore[key] = list
        root._loadSessionsFromStore()
        messages.clear()
        activeSessionIndex = 0
        saveSessionsToCache()
    }

    function switchSession(index) {
        if (index < 0 || index >= sessions.count) return
        if (activeSessionIndex >= 0 && activeSessionIndex < sessions.count) {
            root.saveActiveSession()
        }
        let key = root._presetKey()
        let list = root._allSessionsStore[key] || []
        if (!Array.isArray(list)) list = []
        let entry = list[index] || {}
        messages.clear()
        let store = entry.store || []
        for (let i = 0; i < store.length; i++) {
            let m = store[i]
            messages.append({ role: m.role, content: m.content })
        }
        activeSessionIndex = index
        root.view = "chat"
    }

    function deleteSession(index) {
        if (index < 0 || index >= sessions.count) return
        let key = root._presetKey()
        let list = root._allSessionsStore[key] || []
        list.splice(index, 1)
        root._allSessionsStore[key] = list
        root._loadSessionsFromStore()

        if (sessions.count === 0) {
            messages.clear()
            activeSessionIndex = -1
        } else if (index === activeSessionIndex) {
            let next = Math.min(index, sessions.count - 1)
            root.switchSession(next)
        } else if (index < activeSessionIndex) {
            activeSessionIndex--
        }
        saveSessionsToCache()
    }


    property ListModel presets: ListModel { }

    property int activePresetIndex: -1

    function savePresets() {
        let data = []
        for (let i = 0; i < presets.count; i++) {
            let p = presets.get(i)
            data.push({
                name: p.name,
                url: p.url,
                modelName: p.modelName,
                key: p.key
            })
        }
        configCacheFile.setText(JSON.stringify(data, null, 2))
    }

    function addPreset(name, url, model, key) {
        let cleanName = name.trim() || ("Preset " + (presets.count + 1))
        let cleanUrl = url.trim()
        let cleanModel = model.trim()
        let cleanKey = key.replace(/[\n\r\s]/g, "")

        if (!cleanUrl || !cleanModel || !cleanKey) return

        presets.append({ name: cleanName, url: cleanUrl, modelName: cleanModel, key: cleanKey })
        savePresets()
    }

    function updatePreset(index, name, url, model, key) {
        if (index < 0 || index >= presets.count) return

        let cleanName = name.trim() || ("Preset " + (index + 1))
        let cleanUrl = url.trim()
        let cleanModel = model.trim()
        let cleanKey = key.replace(/[\n\r\s]/g, "")

        if (!cleanUrl || !cleanModel || !cleanKey) return

        presets.set(index, { name: cleanName, url: cleanUrl, modelName: cleanModel, key: cleanKey })
        savePresets()
        if (index === root.activePresetIndex) root.activatePreset(index)
    }

    function deletePreset(index) {
        if (index < 0 || index >= presets.count) return
        presets.remove(index)
        savePresets()
        if (presets.count === 0) {
            root.clearConfig()
        } else if (root.activePresetIndex >= presets.count) {
            root.activatePreset(presets.count - 1)
        } else if (root.activePresetIndex === index) {
            root.activatePreset(Math.min(index, presets.count - 1))
        }
    }

    function activatePreset(index) {
        if (index < 0 || index >= presets.count) return
        let p = presets.get(index)
        root.activePresetIndex = index
        root._apiUrl = p.url
        root._model = p.modelName
        root._apiKey = p.key
        root.configuredUrl = p.url
        root.configuredModel = p.modelName
        root.configuredName = p.name
        root.isConfigured = true
        root.view = "chat"
        root._loadSessionsFromStore()
        if (sessions.count > 0) {
            root.switchSession(0)
        } else {
            messages.clear()
            activeSessionIndex = -1
        }
    }

    function clearConfig() {
        root._apiUrl = ""
        root._model = ""
        root._apiKey = ""
        root.configuredUrl = ""
        root.configuredModel = ""
        root.configuredName = ""
        root.activePresetIndex = -1
        root.isConfigured = false
    }

    property string _encodingPath: ""
    property string _encodingMime: ""
    property string _encodingName: ""
    property bool _encodingIsCode: false

    function addAttachment(path) {
        if (!path) return
        let name = path.split("/").pop()
        let ext = name.split(".").pop().toLowerCase()
        let imageExts = ["png", "jpg", "jpeg", "gif", "webp", "bmp"]

        if (imageExts.indexOf(ext) >= 0) {
            let mimeMap = {
                png: "image/png", jpg: "image/jpeg", jpeg: "image/jpeg",
                gif: "image/gif", webp: "image/webp", bmp: "image/bmp"
            }
            root._encodingPath = path
            root._encodingMime = mimeMap[ext] || "image/png"
            root._encodingName = name
            root._encodingIsCode = false

            if (encodeProc.running) encodeProc.running = false
            encodeProc.command = ["base64", "-w", "0", path]
            encodeProc.running = true
        } else {
            if (readFileProc.running) readFileProc.running = false
            readFileProc.command = ["cat", path]
            root._encodingName = name
            root._encodingPath = path
            root._encodingIsCode = true
            readFileProc.running = true
        }
    }

    Process {
        id: readFileProc

        stdout: StdioCollector {
            onStreamFinished: {
                let content = text
                if (content) {
                    let ext = root._encodingName.split(".").pop().toLowerCase()
                    let lang = ext
                    attachments.append({
                        name: root._encodingName,
                        path: root._encodingPath,
                        mimeType: "text/plain",
                        data: "```" + lang + "\n" + content + "\n```"
                    })
                }
            }
        }
    }

    Process {
        id: encodeProc

        stdout: StdioCollector {
            onStreamFinished: {
                let data = text.replace(/[\n\r\s]/g, "")
                if (data) {
                    attachments.append({
                        name: root._encodingName,
                        path: root._encodingPath,
                        mimeType: root._encodingMime,
                        data: "data:" + root._encodingMime + ";base64," + data
                    })
                }
            }
        }
    }

    function removeAttachment(index) {
        if (index >= 0 && index < attachments.count) {
            attachments.remove(index)
        }
    }

    function clearAttachments() {
        attachments.clear()
    }

    function sendMessage(text) {
        if (root.isLoading || text.trim() === "" || !root.isConfigured) return

        if (activeSessionIndex < 0) root.newSession()

        root.isLoading = true

        let hasAttachments = attachments.count > 0
        let hasImages = false
        let hasCode = false
        let codeText = ""

        if (hasAttachments) {
            for (let i = 0; i < attachments.count; i++) {
                let att = attachments.get(i)
                if (att.mimeType === "text/plain") {
                    hasCode = true
                    codeText += "\n\n" + att.data
                } else {
                    hasImages = true
                }
            }
        }

        let displayText = text || ""
        if (hasImages && !text.trim()) displayText = "[Image attached]"
        if (hasCode && !text.trim()) displayText = "[Code attached]"
        if (hasCode && hasImages && !text.trim()) displayText = "[Image + Code attached]"

        messages.append({ "role": "user", "content": displayText })
        if (activeSessionIndex >= 0) root.saveActiveSession()

        let apiMessages = []
        apiMessages.push({ "role": "system", "content": "You are a helpful assistant. Keep responses concise." })

        for (let i = 0; i < messages.count - 1; i++) {
            let msg = messages.get(i)
            apiMessages.push({ "role": msg.role, "content": msg.content })
        }

        let finalText = text
        if (hasCode) finalText = (text.trim() !== "" ? text + codeText : codeText.trim())

        if (hasImages && hasCode) {
            let contentArray = [{ type: "text", text: finalText }]
            for (let i = 0; i < attachments.count; i++) {
                let att = attachments.get(i)
                if (att.mimeType !== "text/plain") {
                    contentArray.push({ type: "image_url", image_url: { url: att.data } })
                }
            }
            apiMessages.push({ "role": "user", "content": contentArray })
        } else if (hasImages) {
            let contentArray = []
            if (text.trim() !== "") contentArray.push({ type: "text", text: text })
            for (let i = 0; i < attachments.count; i++) {
                let att = attachments.get(i)
                contentArray.push({ type: "image_url", image_url: { url: att.data } })
            }
            apiMessages.push({ "role": "user", "content": contentArray })
        } else {
            apiMessages.push({ "role": "user", "content": finalText || text })
        }

        root.clearAttachments()

        let xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                root.isLoading = false
                if (xhr.status === 200) {
                    try {
                        let data = JSON.parse(xhr.responseText)
                        let reply = data.choices[0].message.content
                        messages.append({ "role": "assistant", "content": reply })
                        if (activeSessionIndex >= 0) root.saveActiveSession()
                    } catch (e) {
                        messages.append({ "role": "assistant", "content": "Error parsing response." })
                    }
                } else if (xhr.status === 401 || xhr.status === 403) {
                    messages.append({ "role": "assistant", "content": "Authentication failed. Check your API key." })
                } else if (xhr.status === 404) {
                    messages.append({ "role": "assistant", "content": "Endpoint not found. Check the API URL." })
                } else {
                    let errorMsg = "API error (HTTP " + xhr.status + ")"
                    try {
                        let err = JSON.parse(xhr.responseText)
                        if (err.error && err.error.message) errorMsg = err.error.message
                    } catch (e) {}
                    messages.append({ "role": "assistant", "content": errorMsg })
                }
            }
        }
        xhr.open("POST", root._apiUrl)
        xhr.setRequestHeader("Content-Type", "application/json")
        xhr.setRequestHeader("Authorization", "Bearer " + root._apiKey)
        xhr.send(JSON.stringify({ model: root._model, messages: apiMessages }))
    }

    function clearChat() {
        messages.clear()
    }

    function regenerate() {
        if (messages.count < 2) return

        let lastUserIndex = -1
        for (let i = messages.count - 1; i >= 0; i--) {
            if (messages.get(i).role === "user") { lastUserIndex = i; break }
        }
        if (lastUserIndex < 0) return

        messages.remove(lastUserIndex + 1, messages.count - lastUserIndex - 1)
        let lastUserMsg = messages.get(lastUserIndex).content
        messages.remove(lastUserIndex, 1)
        root.sendMessage(lastUserMsg)
    }
}
