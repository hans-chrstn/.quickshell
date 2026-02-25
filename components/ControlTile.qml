import QtQuick
import Quickshell
import qs.services

Rectangle {
    id: root
    
    property string icon: ""
    property bool active: false
    property color activeColor: ThemeManager.accentColor
    
    signal clicked()

    width: ThemeManager.controlCenterTileSize
    height: ThemeManager.controlCenterTileSize
    radius: ThemeManager.controlCenterTileRadius
    
    color: active ? activeColor : ThemeManager.contentOnBackgroundColor
    
    opacity: active ? 1.0 : (hh.hovered ? 0.15 : 0.1)
    
    Behavior on color { ColorAnimation { duration: 200 } }
    Behavior on opacity { NumberAnimation { duration: 200 } }
    Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
    
    scale: hh.hovered ? 1.05 : 1.0

    Text {
        anchors.centerIn: parent
        text: root.icon
        font.pixelSize: 18
        color: root.active ? ThemeManager.contentPrimaryColor : ThemeManager.contentOnBackgroundColor
    }

    TapHandler {
        onTapped: root.clicked()
    }

    HoverHandler {
        id: hh
        cursorShape: Qt.PointingHandCursor
    }
}
