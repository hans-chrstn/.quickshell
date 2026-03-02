import QtQuick
import Quickshell
import qs.core

QtObject {
    id: root

    property bool isPreviewMode: false
    property bool isSaveAsActive: false
    property bool isExplorerExpanded: true
    property string pendingDeletePath: ""

    function initialize() {
        FileBrowserManager.switchToNotes()
    }

    function cleanup() {
        root.isSaveAsActive = false
        NotesManager.saveNotes()
    }

    function toggleExplorer() {
        root.isExplorerExpanded = !root.isExplorerExpanded
    }

    function openFile(path, isDir) {
        if (isDir) {
            FileBrowserManager.navigateToPath(path)
        } else {
            NotesManager.openFile(path)
        }
    }

    function confirmDelete(path) {
        root.pendingDeletePath = path
    }

    function executeDelete() {
        NotesManager.deleteFile(root.pendingDeletePath)
        root.pendingDeletePath = ""
    }

    function cancelDelete() {
        root.pendingDeletePath = ""
    }

    function startSaveAs() {
        root.isSaveAsActive = true
    }

    function executeSaveAs(fileName) {
        NotesManager.saveAs(FileBrowserManager.currentPath + "/" + fileName)
        root.isSaveAsActive = false
    }

    function cancelSaveAs() {
        root.isSaveAsActive = false
    }
}
