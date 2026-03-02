pragma Singleton
import QtQuick
import Quickshell
import qs.ui.shared
import qs.shared

Singleton {
    id: root

    property string lastWallpaperPath: Quickshell.env("HOME") + "/Pictures"
    property string lastNotesPath: Quickshell.env("HOME") + "/Documents"
    property string currentMode: ""

    FileSystemInterface {
        id: internalFileSystem
    }

    property alias currentPath: internalFileSystem.currentPath
    property alias isShowingHiddenFiles: internalFileSystem.isShowingHiddenFiles
    property alias filterMode: internalFileSystem.filterMode
    readonly property alias fileModel: internalFileSystem.fileModel
    readonly property alias containsImages: internalFileSystem.containsImages

    function switchToWallpaper() {
        if (root.currentMode === "notes") {
            root.lastNotesPath = internalFileSystem.currentPath
        }
        
        root.currentMode = "wallpaper"
        internalFileSystem.filterMode = "images"
        internalFileSystem.currentPath = root.lastWallpaperPath
        internalFileSystem.refresh()
    }

    function switchToNotes() {
        if (root.currentMode === "wallpaper") {
            root.lastWallpaperPath = internalFileSystem.currentPath
        }
        
        root.currentMode = "notes"
        internalFileSystem.filterMode = "notes"
        internalFileSystem.currentPath = root.lastNotesPath
        internalFileSystem.refresh()
    }

    function refresh() {
        internalFileSystem.refresh()
    }

    function navigateToPath(path) {
        internalFileSystem.navigateToPath(path)
        
        if (root.currentMode === "wallpaper") {
            root.lastWallpaperPath = internalFileSystem.currentPath
        } else if (root.currentMode === "notes") {
            root.lastNotesPath = internalFileSystem.currentPath
        }
    }
    
    function navigateToParent() {
        internalFileSystem.navigateToParent()
        
        if (root.currentMode === "wallpaper") {
            root.lastWallpaperPath = internalFileSystem.currentPath
        } else if (root.currentMode === "notes") {
            root.lastNotesPath = internalFileSystem.currentPath
        }
    }
}
