import QtQuick
import Quickshell
import qs.core

Rectangle {
    id: root
    
    property string tileIcon: ""
    property bool isTileActive: false
    property color activeTileColor: ThemeManager.accentColor
    
    signal tileClicked()

    width: ThemeManager.controlCenterTileSize
    height: ThemeManager.controlCenterTileSize
    radius: ThemeManager.controlCenterTileRadius
    
    color: isTileActive ? activeTileColor : ThemeManager.contentOnBackgroundColor
    
    opacity: isTileActive ? 1.0 : (hoverInteractionHandler.hovered ? 0.15 : 0.1)
    
    Behavior on color { ColorAnimation { duration: 200 } }
    Behavior on opacity { NumberAnimation { duration: 200 } }
    Behavior on scale { 
        NumberAnimation { 
            duration: 300
            easing.type: Easing.OutBack 
        } 
    }
    
    scale: hoverInteractionHandler.hovered ? 1.05 : 1.0

    Text {
        anchors.centerIn: parent
        text: root.tileIcon
        font.pixelSize: 18
        color: root.isTileActive ? ThemeManager.contentPrimaryColor : ThemeManager.contentOnBackgroundColor
    }

    TapHandler {
        onTapped: root.tileClicked()
    }

    HoverHandler {
        id: hoverInteractionHandler
        cursorShape: Qt.PointingHandCursor
    }
}
