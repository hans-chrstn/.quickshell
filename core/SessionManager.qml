pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string currentSessionExec: ""
    property string currentSessionName: "Default"
    
    readonly property string lastSessionCachePath: Quickshell.cachePath("last_session")
    readonly property string sessionsStorePath: Quickshell.cachePath("sessions.json")
    
    readonly property var defaultSessions: [
        { name: "Niri", exec: "niri-session" },
        { name: "Steam", exec: "steam-gamescope" },
        { name: "Hyprland", exec: "start-hyprland" }
    ]

    ListModel { id: sessionModel }
    property alias model: sessionModel

    FileView {
        id: lastSessionFile
        path: root.lastSessionCachePath
        onLoaded: {
            let last = text().trim()
            if (last) {
                root.currentSessionExec = last
                finalizeSelection()
            }
        }
    }

    FileView {
        id: sessionsStoreFile
        path: root.sessionsStorePath
        onLoaded: loadSessions()
    }

    property bool _initialLoadDone: false

    function loadSessions() {
        let content = sessionsStoreFile.text().trim()
        let data = []
        
        if (content) {
            try {
                data = JSON.parse(content)
            } catch (e) { }
        }
        
        if (!data || data.length === 0) {
            data = defaultSessions
        }
        
        sessionModel.clear()
        data.forEach(item => sessionModel.append(item))
        _initialLoadDone = true
        finalizeSelection()
    }

    function saveSessions() {
        if (!_initialLoadDone) return
        
        let data = []
        for (let i = 0; i < sessionModel.count; i++) {
            data.push({
                name: sessionModel.get(i).name,
                exec: sessionModel.get(i).exec
            })
        }
        sessionsStoreFile.setText(JSON.stringify(data, null, 4))
    }

    function addSession(name, exec) {
        if (!name || !exec) return
        sessionModel.append({ name: name, exec: exec })
        saveSessions()
    }

    function deleteSession(index) {
        if (index >= 0 && index < sessionModel.count) {
            sessionModel.remove(index)
            saveSessions()
            finalizeSelection()
        }
    }

    function resetToDefaults() {
        sessionModel.clear()
        defaultSessions.forEach(item => sessionModel.append(item))
        _initialLoadDone = true
        saveSessions()
        finalizeSelection()
    }

    function finalizeSelection() {
        let found = false
        for (let i = 0; i < sessionModel.count; i++) {
            if (sessionModel.get(i).exec === root.currentSessionExec) {
                root.currentSessionName = sessionModel.get(i).name
                found = true
                break
            }
        }
        
        if (!found && sessionModel.count > 0) {
            root.currentSessionName = sessionModel.get(0).name
            root.currentSessionExec = sessionModel.get(0).exec
        }
    }

    function selectSession(index) {
        if (index < 0 || index >= sessionModel.count) return
        let item = sessionModel.get(index)
        root.currentSessionName = item.name
        root.currentSessionExec = item.exec
        lastSessionFile.setText(item.exec)
    }

    Component.onCompleted: {
        Qt.callLater(() => {
            if (!_initialLoadDone) loadSessions()
        })
    }
}
