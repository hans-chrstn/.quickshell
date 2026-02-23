import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services

Rectangle {
    id: root
    
    property string icon: ""
    property bool active: false
    property color activeColor: ThemeService.accentColor
    
    signal clicked()

    width: ThemeService.controlCenterTileSize
    height: ThemeService.controlCenterTileSize
    radius: ThemeService.controlCenterTileRadius
    
    color: active ? activeColor : ThemeService.backgroundContent
    
    readonly property bool isHighlighted: hh.hovered || activeFocus
    
    opacity: active ? 1.0 : (isHighlighted ? 0.15 : 0.1)
    
    Behavior on color { ColorAnimation { duration: 200 } }
    Behavior on opacity { NumberAnimation { duration: 200 } }
    Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
    
    scale: isHighlighted ? 1.05 : 1.0

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: "transparent"
        border.color: "white"
        border.width: root.activeFocus ? 2 : 0
        visible: root.activeFocus
    }

    Text {
        anchors.centerIn: parent
        text: root.icon
        font.pixelSize: 18
        color: root.active ? ThemeService.primaryContent : ThemeService.backgroundContent
    }

    TapHandler {
        onTapped: root.clicked()
    }

    HoverHandler {
        id: hh
        cursorShape: Qt.PointingHandCursor
    }
}
