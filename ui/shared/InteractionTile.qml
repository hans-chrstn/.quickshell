import QtQuick
import Quickshell
import qs.core
import qs.ui.shared

BaseButton {
    id: root
    
    property string tileIcon: ""
    property bool isTileActive: false
    property color activeTileColor: ThemeManager.accentColor
    
    signal tileClicked()
    onClicked: tileClicked()

    width: ThemeManager.controlCenterTileSize
    height: ThemeManager.controlCenterTileSize
    
    Rectangle {
        anchors.fill: parent
        radius: ThemeManager.controlCenterTileRadius
        color: root.isTileActive ? root.activeTileColor : ThemeManager.contentOnBackgroundColor
        opacity: root.isTileActive ? 1.0 : (root.isHovered ? 0.15 : 0.1)
        
        Behavior on color { ColorAnimation { duration: 200 } }
        Behavior on opacity { NumberAnimation { duration: 200 } }

        Text {
            anchors.centerIn: parent
            text: root.tileIcon
            font.pixelSize: 18
            color: root.isTileActive ? ThemeManager.contentPrimaryColor : ThemeManager.contentOnBackgroundColor
        }
    }
}
