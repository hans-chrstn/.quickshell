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
    readonly property bool isConnected: niri.isConnected()

    Niri {
        id: niri
        Component.onCompleted: connect()
        
        onErrorOccurred: (err) => console.error("[NiriManager] Error:", err)
    }

    function focusWorkspaceById(id) {
        niri.focusWorkspaceById(id)
    }

    function focusWindowById(id) {
        niri.focusWindow(id)
    }

    function closeWindowById(id) {
        niri.closeWindow(id)
    }

    property var runningApplications: ({})

    Instantiator {
        model: niri.windows
        delegate: QtObject {
            readonly property string normalizedAppId: model.appId ? model.appId.toLowerCase() : ""
            readonly property int windowId: model.id
            
            Component.onCompleted: {
                if (normalizedAppId) {
                    if (!root.runningApplications[normalizedAppId]) {
                        root.runningApplications[normalizedAppId] = []
                    }
                    root.runningApplications[normalizedAppId].push(windowId)
                    root.runningApplicationsChanged()
                }
            }
            Component.onDestruction: {
                if (normalizedAppId && root.runningApplications[normalizedAppId]) {
                    let arr = root.runningApplications[normalizedAppId]
                    let index = arr.indexOf(windowId)
                    if (index !== -1) {
                        arr.splice(index, 1)
                        if (arr.length === 0) {
                            delete root.runningApplications[normalizedAppId]
                        }
                        root.runningApplicationsChanged()
                    }
                }
            }
        }
    }

    function isApplicationRunning(desktopAppId) {
        if (!desktopAppId) return false
        
        let searchId = desktopAppId.toString().replace(".desktop", "").toLowerCase()
        
        if (root.runningApplications[searchId]) return true

        for (let key in root.runningApplications) {
            if (key.includes(searchId) || searchId.includes(key)) return true
        }
        return false
    }

    function focusApplication(desktopAppId) {
        if (!desktopAppId) return
        
        let searchId = desktopAppId.toString().replace(".desktop", "").toLowerCase()
        
        if (root.runningApplications[searchId]) {
            let ids = root.runningApplications[searchId]
            if (ids.length > 0) focusWindowById(ids[ids.length - 1])
            return
        }

        for (let key in root.runningApplications) {
            if (key.includes(searchId) || searchId.includes(key)) {
                let ids = root.runningApplications[key]
                if (ids.length > 0) focusWindowById(ids[ids.length - 1])
                return
            }
        }
    }

    function getApplicationWindows(desktopAppId) {
        if (!desktopAppId) return []
        
        let searchId = desktopAppId.toString().replace(".desktop", "").toLowerCase()
        let windows = []
        
        for (let i = 0; i < niri.windows.count; i++) {
            let index = niri.windows.index(i, 0)
            let appId = niri.windows.data(index, 259)
            
            if (appId && appId.toLowerCase().includes(searchId)) {
                let id = niri.windows.data(index, 257)
                let title = niri.windows.data(index, 258)
                windows.push({ id: id, title: title })
            }
        }
        
        return windows
    }
}
