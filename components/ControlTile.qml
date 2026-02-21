import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import qs.config

Rectangle {
    id: root
    
    property string icon: ""
    property bool active: false
    property bool enabled: true
    property color activeColor: FrameConfig.accentColor
    
    signal clicked()

    width: FrameConfig.controlCenterTileSize; height: FrameConfig.controlCenterTileSize; radius: FrameConfig.controlCenterTileRadius
    color: active ? activeColor : "#FFFFFF"
    opacity: enabled ? (active ? 1.0 : 0.15) : 0.05
    
    scale: tapHandler.pressed ? 0.92 : (hoverHandler.hovered ? 1.05 : 1.0)
    Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
    Behavior on color { ColorAnimation { duration: 250 } }
    Behavior on opacity { NumberAnimation { duration: 250 } }

    HoverHandler { id: hoverHandler; cursorShape: Qt.PointingHandCursor }

    Rectangle {
        anchors.centerIn: parent
        width: parent.width * 1.5; height: parent.height * 1.5
        radius: width / 2
        color: root.activeColor
        opacity: root.active ? 0.25 : 0.0
        z: -1
        
        layer.enabled: root.active
        layer.effect: MultiEffect { blurEnabled: true; blur: 0.6 }
        
        Behavior on opacity { NumberAnimation { duration: 400 } }
    }

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: "white"
        opacity: hoverHandler.hovered ? 0.2 : 0.0
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: "transparent"
        border.color: "white"
        border.width: 1
        opacity: root.active ? 0.3 : 0.1
    }

    Text {
        id: iconText
        anchors.centerIn: parent
        text: root.icon
        color: root.active ? "black" : "#FFFFFF"
        font.pixelSize: 22 
        opacity: root.enabled ? 1.0 : 0.3
        renderType: Text.NativeRendering
    }

    TapHandler { 
        id: tapHandler
        enabled: root.enabled
        onTapped: root.clicked() 
    }
}
