pragma Singleton
import QtQuick
import Quickshell
import qs.components

Singleton {
    id: root

    FileBrowserLogic {
        id: fileBrowserLogic
    }

    property alias currentPath: fileBrowserLogic.currentPath
    property alias showHidden: fileBrowserLogic.showHidden
    readonly property alias model: fileBrowserLogic.model
    readonly property alias hasImages: fileBrowserLogic.hasImages

    function refresh(): void {
        fileBrowserLogic.refresh()
    }

    function changeDirectory(path: string): void {
        fileBrowserLogic.changeDirectory(path)
    }
    
    function goUp(): void {
        fileBrowserLogic.goUp()
    }
}
