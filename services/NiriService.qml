pragma Singleton
import QtQuick
import Quickshell
import QtQml.Models
import Niri 0.1

Singleton {
    id: root

    property alias workspaces: niri.workspaces
    property alias windows: niri.windows
    property alias focusedWindow: niri.focusedWindow
    property bool connected: niri.isConnected()

    Niri {
        id: niri
        Component.onCompleted: connect()
        
        onConnected: console.log("[NiriService] Connected to Niri IPC")
        onErrorOccurred: (err) => console.error("[NiriService] Error:", err)
    }

    function focusWorkspace(id) {
        niri.focusWorkspaceById(id)
    }

    function focusWindow(id) {
        niri.focusWindow(id)
    }

    function closeWindow(id) {
        niri.closeWindow(id)
    }

    function closeFocusedWindow() {
        niri.closeWindowOrFocused()
    }

    property var runningApps: ({})

    Instantiator {
        model: niri.windows
        delegate: QtObject {
            readonly property string nAppId: model.appId ? model.appId.toLowerCase() : ""
            readonly property int nWinId: model.id
            
            Component.onCompleted: {
                if (nAppId) {
                    if (!root.runningApps[nAppId]) root.runningApps[nAppId] = []
                    root.runningApps[nAppId].push(nWinId)
                    root.runningAppsChanged()
                }
            }
            Component.onDestruction: {
                if (nAppId && root.runningApps[nAppId]) {
                    let arr = root.runningApps[nAppId]
                    let idx = arr.indexOf(nWinId)
                    if (idx !== -1) {
                        arr.splice(idx, 1)
                        if (arr.length === 0) delete root.runningApps[nAppId]
                        root.runningAppsChanged()
                    }
                }
            }
        }
    }

    function isAppRunning(desktopAppId) {
        if (!desktopAppId) return false
        
        let searchId = desktopAppId.toString().replace(".desktop", "").toLowerCase()
        
        if (root.runningApps[searchId]) return true

        for (let key in root.runningApps) {
            if (key.includes(searchId) || searchId.includes(key)) return true
        }
        return false
    }

    function focusApp(desktopAppId) {
        if (!desktopAppId) return
        
        let searchId = desktopAppId.toString().replace(".desktop", "").toLowerCase()
        
        if (root.runningApps[searchId]) {
            let ids = root.runningApps[searchId]
            if (ids.length > 0) focusWindow(ids[ids.length - 1])
            return
        }

        for (let key in root.runningApps) {
            if (key.includes(searchId) || searchId.includes(key)) {
                let ids = root.runningApps[key]
                if (ids.length > 0) focusWindow(ids[ids.length - 1])
                return
            }
        }
    }

    function getAppWindows(desktopAppId) {
        if (!desktopAppId) return []
        
        let searchId = desktopAppId.toString().replace(".desktop", "").toLowerCase()
        let windows = []
        
        for (let i = 0; i < niri.windows.count; i++) {
            let idx = niri.windows.index(i, 0)
            let appId = niri.windows.data(idx, 259)
            
            if (appId && appId.toLowerCase().includes(searchId)) {
                let id = niri.windows.data(idx, 257)
                let title = niri.windows.data(idx, 258)
                windows.push({ id: id, title: title })
            }
        }
        
        return windows
    }
}
