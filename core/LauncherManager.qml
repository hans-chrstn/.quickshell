pragma Singleton

import QtQuick
import Quickshell
import qs.core
import qs.shared

Singleton {
    id: root

    property bool active: false
    property bool isClosing: false
    property string searchText: ""
    property int selectedIndex: 0

    property ListModel appModel: ListModel { }

    property ListModel resultsModel: ListModel { }
    readonly property alias model: root.resultsModel

    readonly property var recentAppIds: ({})

    readonly property var systemActions: [
        { name: "Settings", icon: ThemeManager.iconSettings, internal: "open_settings" },
        { name: "Task Manager", icon: ThemeManager.iconTasks, internal: "open_taskManager" },
        { name: "Lock Screen", icon: ThemeManager.iconLock, internal: "lock_screen" },
        { name: "Leave / Power", icon: ThemeManager.iconPower, internal: "power_menu" },
        { name: "Reload Shell", icon: ThemeManager.iconRevert, internal: "reload_shell" }
    ]

    property var webSearchLink: "https://www.google.com/search?q="

    function toggle() {
        if (root.active && !root.isClosing) {
            root.close()
        } else {
            root.open()
        }
    }

    function open() {
        root.isClosing = false
        root.searchText = ""
        root.selectedIndex = 0
        root.updateResults()
        root.active = true
    }

    function close() {
        if (!root.active || root.isClosing) {
            return
        }
        root.isClosing = true
        closeTimer.restart()
    }

    Timer {
        id: closeTimer
        interval: 350
        onTriggered: {
            root.active = false
            root.isClosing = false
            root.searchText = ""
        }
    }

    function clearRecents() {
        root.recentAppIds = {}
        if (root.active) {
            root.updateResults()
        }
    }

    function executeSelected() {
        let filter = root.searchText.trim()

        if (filter.startsWith(">")) {
            let cmd = filter.substring(1).trim()
            if (cmd) {
                Quickshell.execDetached(["sh", "-c", cmd])
                root.recordLaunch("cmd_" + cmd)
            }
            root.close()
            return
        }

        if (resultsModel.count > 0 && root.selectedIndex >= 0 && root.selectedIndex < resultsModel.count) {
            let item = resultsModel.get(root.selectedIndex)

            if (item.type === "app" && item.app) {
                root.recordLaunch(item.id)
                if (!WindowManager.focusApplication(item.app.id)) {
                    item.app.execute()
                }
            } else if (item.type === "system") {
                root.executeSystemAction(item.internal)
                return
            } else if (item.type === "cmd") {
                root.close()
                return
            } else if (item.type === "calc") {
                ClipboardManager.setText(String(item.name))
                root.close()
                return
            } else if (item.type === "window") {
                WindowManager.focusWindowById(item.id)
            } else if (item.type === "clip") {
                ClipboardManager.setText(item.name)
            } else if (item.type === "browser") {
                Quickshell.execDetached(["xdg-open", root.webSearchLink + encodeURIComponent(item.description)])
            }
            root.close()
        }
    }

    function executeSystemAction(internal) {
        root.close()
        if (internal === "open_settings") {
            ViewManager.openSettings()
        } else if (internal === "open_taskManager") {
            ViewManager.openTaskManager()
        } else if (internal === "lock_screen") {
            Quickshell.execDetached(["loginctl", "lock-session"])
        } else if (internal === "power_menu") {
            Quickshell.execDetached(["sh", "-c", "systemctl poweroff || loginctl poweroff"])
        } else if (internal === "reload_shell") {
            Quickshell.reload(false)
        }
    }

    function recordLaunch(id) {
        let next = Object.assign({}, root.recentAppIds)
        next[id] = Date.now()
        root.recentAppIds = next
    }

    function updateResults() {
        let filter = root.searchText.trim().toLowerCase()
        let results = []

        if (filter.startsWith(">")) {
            results.push({
                type: "cmd", id: "run_cmd", name: "Run Command", icon: "󰆍",
                description: filter.substring(1).trim() || "Type command...", score: 1000
            })
        } else if (filter.startsWith("=")) {
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
            } catch (e) {}
        } else if (filter.startsWith("*")) {
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
        } else {
            for (let i = 0; i < systemActions.length; i++) {
                let action = systemActions[i]
                let score = filter === "" ? (100 - i) : FuzzySearch.score(filter, action.name)
                if (score > 0) {
                    results.push({
                        type: "system", id: "", name: action.name, icon: action.icon,
                        internal: action.internal, description: "System Action", score: score
                    })
                }
            }

            let windows = WindowManager.getAllWindows()
            for (let i = 0; i < windows.length; i++) {
                let win = windows[i]
                let winId = win.id.toString()
                let appId = win.appId || ""
                let title = win.title || "Untitled"
                let score = FuzzySearch.score(filter, title)
                if (score > 0) {
                    results.push({
                        type: "window", id: winId.toString(), name: title, icon: "󰖯",
                        description: "Focus Window (" + appId + ")", score: score * 0.9
                    })
                }
            }

            let apps = DesktopEntries.applications.values
            for (let i = 0; i < apps.length; i++) {
                let app = apps[i]
                let score = 0
                if (filter === "") {
                    let recentIdx = root.recentAppIds[app.id] ? 1 : 0
                    if (recentIdx) {
                        score = 80
                    } else if (results.length < 15) {
                        score = 10 - i * 0.01
                    }
                } else {
                    let nameScore = FuzzySearch.score(filter, app.name)
                    let descScore = app.description ? FuzzySearch.score(filter, app.description) * 0.4 : 0
                    score = Math.max(nameScore, descScore)
                }
                if (score > 0) {
                    results.push({
                        type: "app", id: app.id, name: app.name,
                        app: app,
                        icon: app.icon ? app.icon.toString() : "application-x-executable",
                        description: app.description || "Application", score: score
                    })
                }
            }

            if (filter !== "" && results.length < 5) {
                let searchScore = 90
                results.push({
                    type: "browser", id: "web_search", name: "Search the web",
                    icon: "󰖟", description: filter, score: searchScore
                })
            }
        }

        results.sort((a, b) => b.score - a.score)

        resultsModel.clear()
        for (let i = 0; i < results.length; i++) {
            resultsModel.append(results[i])
        }

        if (root.selectedIndex >= resultsModel.count) {
            root.selectedIndex = 0
        }
    }

    onSearchTextChanged: {
        root.selectedIndex = 0
        root.updateResults()
    }

    function populateAppModel() {
        appModel.clear()
        let apps = DesktopEntries.applications.values.slice()
        apps.sort((a, b) => a.name.toLowerCase().localeCompare(b.name.toLowerCase()))
        for (let i = 0; i < apps.length; i++) {
            appModel.append({ "app": apps[i] })
        }
    }

    Component.onCompleted: {
        root.populateAppModel()
    }

    Connections {
        target: DesktopEntries.applications
        function onValuesChanged() {
            root.populateAppModel()
            if (root.active) root.updateResults()
        }
    }

    Connections {
        target: ClipboardManager
        function onHistoryCleared() { if (root.active) root.updateResults() }
    }
}
