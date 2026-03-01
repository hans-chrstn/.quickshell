import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.core
import qs.ui.shared

FocusScope {
    id: root
    
    property alias showSettings: rootHeader.showSettings
    property alias gridView: explorerGrid.gridView
    property alias settingsBtn: rootHeader.settingsButton

    Keys.onUpPressed: {
        rootHeader.settingsButton.forceActiveFocus()
    }
    Keys.onDownPressed: {
        explorerGrid.gridView.forceActiveFocus()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 20

        WallpaperExplorerHeader {
            id: rootHeader
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !rootHeader.showSettings
            
            WallpaperExplorerGrid {
                id: explorerGrid
            }
        }
    }
}
