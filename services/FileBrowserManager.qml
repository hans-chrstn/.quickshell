pragma Singleton
import QtQuick
import Quickshell
import qs.components
import qs.utilities

Singleton {
    id: root

    FileSystemInterface {
        id: internalFileSystem
    }

    property alias currentPath: internalFileSystem.currentPath
    property alias isShowingHiddenFiles: internalFileSystem.isShowingHiddenFiles
    readonly property alias fileModel: internalFileSystem.fileModel
    readonly property alias containsImages: internalFileSystem.containsImages

    function refresh() {
        internalFileSystem.refresh()
    }

    function navigateToPath(path) {
        internalFileSystem.navigateToPath(path)
    }
    
    function navigateToParent() {
        internalFileSystem.navigateToParent()
    }
}
