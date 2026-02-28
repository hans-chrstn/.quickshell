pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string homeDir: Quickshell.env("HOME")
    readonly property string defaultNotesDir: homeDir + "/Documents"
    readonly property string recentFilesCachePath: Quickshell.cachePath("recent_notes.json")
    
    property string content: ""
    property string currentFilePath: "" 
    property var recentFiles: []
    property bool isReady: false
    property bool hasUnsavedChanges: false

    function createNewNote() {
        if (hasUnsavedChanges) {
            saveNotes()
        }
        root.content = "# New Note\n\n"
        root.currentFilePath = "" 
        root.hasUnsavedChanges = false
    }

    function openFile(path) {
        if (!path) {
            return
        }
        if (hasUnsavedChanges) {
            saveNotes()
        }
        root.currentFilePath = path
        notesFile.path = path
        addToRecent(path)
    }

    function triggerRefresh() {
        Quickshell.execDetached(["sync"])
        refreshTimer.restart()
    }

    function saveNotes() {
        if (!isReady) {
            return
        }
        
        if (!root.currentFilePath) {
            let filename = "note_" + new Date().getTime() + ".md"
            root.currentFilePath = FileBrowserManager.currentPath + "/" + filename
        }
        
        notesFile.path = root.currentFilePath
        
        Qt.callLater(() => {
            notesFile.setText(root.content)
            root.hasUnsavedChanges = false
            addToRecent(root.currentFilePath)
            triggerRefresh()
        })
    }

    function deleteRecent(path) {
        let list = [...root.recentFiles]
        let idx = list.indexOf(path)
        if (idx !== -1) {
            list.splice(idx, 1)
            root.recentFiles = list
            recentFilesStore.setText(JSON.stringify(root.recentFiles))
        }
    }

    function deleteFile(path) {
        if (!path) {
            return
        }
        
        Quickshell.execDetached(["rm", path])
        deleteRecent(path)
        
        if (root.currentFilePath === path) {
            root.currentFilePath = ""
            root.content = "# New Note\n\n"
            root.hasUnsavedChanges = false
        }
        
        triggerRefresh()
    }

    function saveAs(path) {
        if (!path) {
            return
        }

        if (root.currentFilePath !== "" && root.currentFilePath !== path) {
            Quickshell.execDetached(["mv", root.currentFilePath, path])
            deleteRecent(root.currentFilePath)
        }

        root.currentFilePath = path
        saveNotes()
    }

    function addToRecent(path) {
        if (!path) {
            return
        }
        let list = [...root.recentFiles]
        let idx = list.indexOf(path)
        if (idx !== -1) {
            list.splice(idx, 1)
        }
        list.unshift(path)
        root.recentFiles = list.slice(0, 15)
        recentFilesStore.setText(JSON.stringify(root.recentFiles))
    }

    function loadRecentFiles() {
        let text = recentFilesStore.text()
        if (text) {
            try {
                root.recentFiles = JSON.parse(text)
            } catch(e) {
                console.error("Failed to parse recent files")
            }
        }
    }

    FileView {
        id: notesFile
        path: root.currentFilePath
        blockLoading: true 
        printErrors: false 
        onLoaded: {
            root.content = text() || ""
            root.isReady = true
            root.hasUnsavedChanges = false
        }
    }

    FileView {
        id: recentFilesStore
        path: root.recentFilesCachePath
        onLoaded: {
            root.loadRecentFiles()
        }
    }

    Timer {
        id: autoSaveTimer
        interval: 3000
        repeat: false
        onTriggered: {
            root.saveNotes()
        }
    }

    Timer {
        id: refreshTimer
        interval: 500
        repeat: false
        onTriggered: {
            FileBrowserManager.refresh()
        }
    }

    onContentChanged: {
        if (isReady && currentFilePath !== "") {
            root.hasUnsavedChanges = true
            autoSaveTimer.restart()
        }
    }

    Component.onCompleted: {
        root.isReady = true
        root.loadRecentFiles()
    }
}
