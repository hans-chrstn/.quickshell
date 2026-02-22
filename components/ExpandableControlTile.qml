import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services

Rectangle {
    id: root
    
    property string icon: ""
    property string label: ""
    property bool active: false
    property color activeColor: ThemeService.accentColor
    
    signal clicked()
    signal longPressed()

    width: hh.hovered ? 140 : ThemeService.controlCenterTileSize
    height: ThemeService.controlCenterTileSize
    radius: ThemeService.controlCenterTileRadius
    
    color: active ? activeColor : ThemeService.backgroundContent
    opacity: active ? 1.0 : (hh.hovered ? 0.15 : 0.1)
    
    clip: true
    
    Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }
    Behavior on color { ColorAnimation { duration: 200 } }
    Behavior on opacity { NumberAnimation { duration: 200 } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: (ThemeService.controlCenterTileSize - 18) / 2
        spacing: 12

        Text {
            text: root.icon
            font.pixelSize: 18
            color: root.active ? ThemeService.primaryContent : ThemeService.backgroundContent
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            text: root.label
            color: root.active ? ThemeService.primaryContent : ThemeService.backgroundContent
            font.pixelSize: 11; font.weight: Font.Bold
            visible: root.width > ThemeService.controlCenterTileSize + 20
            opacity: visible ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }
    }

    TapHandler {
        onTapped: root.clicked()
        onLongPressed: root.longPressed()
    }

    HoverHandler {
        id: hh
        cursorShape: Qt.PointingHandCursor
    }
}