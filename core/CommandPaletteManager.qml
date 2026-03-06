pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.core
import qs.shared

Singleton {
    id: root

    property bool active: false
    property string searchText: ""
    property int selectedIndex: 0
    property var recentAppIds: []
    readonly property string recentsCachePath: Quickshell.cachePath("palette_recents.json")

    property ListModel resultsModel: ListModel { }
    readonly property alias model: root.resultsModel

    readonly property var systemActions: [
        { name: "Lock Screen", icon: "󰌾", action: () => LockManager.lock() },
        { name: "Restart Shell", icon: "󰑓", action: () => Quickshell.reload(false) },
        { name: "Quit Shell", icon: "󰈆", action: () => Qt.quit() },
        { name: "Open Settings", icon: "󰒓", action: () => ViewManager.openWindow("settings") },
        { name: "Open Task Manager", icon: "󰍛", action: () => ViewManager.openWindow("taskManager") },
        { name: "Open Notepad", icon: "󰠮", action: () => ViewManager.openWindow("notes") },
        { name: "Refresh Wallpaper", icon: "󰸉", action: () => WallpaperManager.applyWallpaper() },
        { name: "Clear Clipboard History", icon: "󰆴", action: () => ClipboardManager.clear() },
        { name: "Clear Recent Apps", icon: "󰆴", action: () => root.clearRecents() }
    ]

    function clearRecents() {
        root.recentAppIds = []
        recentsFile.setText("[]")
        root.updateResults()
    }

    function open() {
        root.searchText = ""
        root.selectedIndex = 0
        root.updateResults()
        root.active = true
    }

    function close() {
        root.active = false
        root.searchText = ""
    }

    function toggle() {
        if (root.active) root.close()
        else root.open()
    }

    function executeSelected() {
        let filter = root.searchText.trim()
        
        if (filter.startsWith(">")) {
            let cmd = filter.substring(1).trim()
            if (cmd !== "") Quickshell.execDetached(["sh", "-c", cmd])
            ViewManager.closeWindow("commandPalette")
            return
        }

        if (resultsModel.count > 0 && root.selectedIndex >= 0 && root.selectedIndex < resultsModel.count) {
            let item = resultsModel.get(root.selectedIndex)
            
            if (item.type === "app") {
                let app = DesktopEntries.applications.values.find(a => a.id === item.id)
                if (app) {
                    root.recordLaunch(app.id)
                    if (!NiriManager.focusApplication(app.id)) app.execute()
                }
            } else if (item.type === "system") {
                let sysAction = root.systemActions.find(a => a.name === item.name)
                if (sysAction) sysAction.action()
            } else if (item.type === "calc") {
                ClipboardManager.copyToClipboard(item.name)
            } else if (item.type === "clip") {
                ClipboardManager.copyToClipboard(item.name)
            } else if (item.type === "window") {
                NiriManager.focusWindowById(item.id)
            } else if (item.type === "browser") {
                let app = DesktopEntries.applications.values.find(a => a.id === item.id)
                if (app && app.command && app.command.length > 0) {
                    let query = filter.startsWith("?") ? filter.substring(1).trim() : filter
                    let url = "https://www.google.com/search?q=" + encodeURIComponent(query)
                    Quickshell.execDetached([app.command[0], url])
                }
            }
        }
        ViewManager.closeWindow("commandPalette")
    }

    function recordLaunch(id) {
        let recents = [...root.recentAppIds]
        let idx = recents.indexOf(id)
        if (idx !== -1) recents.splice(idx, 1)
        recents.unshift(id)
        root.recentAppIds = recents.slice(0, 20)
        recentsFile.setText(JSON.stringify(root.recentAppIds))
    }

    function updateResults() {
        let filter = root.searchText.trim().toLowerCase()
        let results = []

        if (filter.startsWith(">")) {
            results.push({
                type: "cmd", id: "run_cmd", name: "Run Command", icon: "󰆍",
                description: filter.substring(1).trim() || "Type command...", score: 1000
            })
        } 
        else if (filter.startsWith("=")) {
            let expr = filter.substring(1).trim()
            try {
                if (expr !== "") {
                    let cleanExpr = expr.replace(/\^/g, "**")
                                        .replace(/ln\(/g, "log(")
                                        .replace(/log\(/g, "log10(")
                    
                    let res = (new Function("with(Math) { return " + cleanExpr + " }"))()
                    
                    if (typeof res === "number" && !isNaN(res)) {
                        results.push({
                            type: "calc", id: "calc", name: res.toLocaleString(), icon: "󰪚",
                            description: "Result (Enter to copy)", score: 1000
                        })
                    }
                }
            } catch(e) {}
        }
        else if (filter.startsWith("*")) {
            let clipQuery = filter.substring(1).trim()
            let clips = ClipboardManager.history
            for (let i = 0; i < clips.length; i++) {
                let clip = clips[i]
                let score = clipQuery === "" ? (100 - i) : FuzzySearch.score(clipQuery, clip)
                if (score > 0) {
                    results.push({
                        type: "clip", id: "clip_" + i, name: clip, icon: "󰅍",
                        description: "Clipboard Snippet", score: score
                    })
                }
            }
        }
        else {
            for (let i = 0; i < systemActions.length; i++) {
                let action = systemActions[i]
                let score = filter === "" ? (100 - i) : FuzzySearch.score(filter, action.name)
                if (score > 0) {
                    results.push({
                        type: "system", id: "", name: action.name, icon: action.icon,
                        description: "System Action", score: score * 1.1
                    })
                }
            }

            if (filter !== "") {
                for (let i = 0; i < NiriManager.windows.count; i++) {
                    let idx = NiriManager.windows.index(i, 0)
                    let title = NiriManager.windows.data(idx, 258) || ""
                    let appId = NiriManager.windows.data(idx, 259) || ""
                    let winId = NiriManager.windows.data(idx, 257)
                    
                    let score = FuzzySearch.score(filter, title)
                    if (score > 0) {
                        results.push({
                            type: "window", id: winId.toString(), name: title, icon: "󰖯",
                            description: "Focus Window (" + appId + ")", score: score * 0.9
                        })
                    }
                }
            }

            let apps = DesktopEntries.applications.values
            for (let i = 0; i < apps.length; i++) {
                let app = apps[i]
                let score = 0
                
                if (filter === "") {
                    let recentIdx = root.recentAppIds.indexOf(app.id)
                    if (recentIdx !== -1) score = 80 - recentIdx
                    else if (results.length < 15) score = 10 - i * 0.01 
                } else {
                    let nameScore = FuzzySearch.score(filter, app.name)
                    let descScore = app.description ? FuzzySearch.score(filter, app.description) * 0.4 : 0
                    score = Math.max(nameScore, descScore)
                }

                if (score > 0) {
                    results.push({
                        type: "app", id: app.id, name: app.name, 
                        icon: app.icon ? app.icon.toString() : "application-x-executable",
                        description: app.description || "Application", score: score
                    })
                }
            }

            if (filter !== "" && results.length < 5) {
                let browsers = apps.filter(a => 
                    a.categories.includes("WebBrowser") || 
                    ["firefox", "chrome", "chromium", "brave", "zen"].some(b => a.name.toLowerCase().includes(b))
                )
                
                for (let browser of browsers) {
                    results.push({
                        type: "browser", id: browser.id, name: "Search Google in " + browser.name,
                        icon: browser.icon ? browser.icon.toString() : "internet-web-browser",
                        description: filter.startsWith("?") ? filter.substring(1).trim() : filter,
                        score: 5
                    })
                }
            }
        }

        results.sort((a, b) => b.score - a.score)
        resultsModel.clear()
        let limit = filter === "" ? 10 : 20
        for (let i = 0; i < Math.min(results.length, limit); i++) {
            resultsModel.append(results[i])
        }
        if (root.selectedIndex >= resultsModel.count) root.selectedIndex = 0
    }

    FileView {
        id: recentsFile
        path: root.recentsCachePath
        onLoaded: {
            try {
                let content = text()
                if (content && content.trim() !== "") {
                    let data = JSON.parse(content)
                    if (Array.isArray(data)) root.recentAppIds = data
                }
            } catch (e) {}
            if (root.active) root.updateResults()
        }
    }

    onSearchTextChanged: {
        root.selectedIndex = 0
        updateResults()
    }

    Connections {
        target: DesktopEntries.applications
        function onValuesChanged() { if (root.active) root.updateResults() }
    }

    Connections {
        target: ClipboardManager
        function onHistoryCleared() { if (root.active) root.updateResults() }
    }
}
