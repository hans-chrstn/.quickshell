import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.core
import qs.ui.shared

ClippingRectangle {
    id: root
    
    property alias gridView: grid
    
    anchors.fill: parent
    color: "transparent"
    radius: 0
    
    GridView { 
        id: grid
        anchors.fill: parent
        anchors.margins: 10
        model: FileBrowserManager.fileModel
        cellWidth: 124
        cellHeight: 124
        clip: false
        
        onCurrentIndexChanged: {
            positionViewAtIndex(currentIndex, GridView.Contain)
            let item = model.get(currentIndex)
            if (item && !item.isDir) {
                WallpaperManager.previewWallpaperPath = item.path
            }
        }
        
        function activateItem() {
            let item = model.get(currentIndex)
            if (item && item.isDir) {
                FileBrowserManager.navigateToPath(item.path)
            }
        }

        Keys.onReturnPressed: {
            activateItem()
        }
        Keys.onEnterPressed: {
            activateItem()
        }
        Keys.onSpacePressed: {
            activateItem()
        }

        Behavior on contentY {
            NumberAnimation {
                duration: 400
                easing.type: Easing.OutExpo
            }
        }
        
        delegate: WallpaperExplorerDelegate {
            modelData: model
            gridView: grid
        }
    }
}
