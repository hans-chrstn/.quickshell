import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config

Rectangle {
    id: root
    
    property string icon: ""
    property bool active: false
    property bool enabled: true
    property color activeColor: FrameConfig.accentColor
    
    signal clicked()

    width: 44; height: 44; radius: 22
    color: active ? activeColor : "white"
    opacity: enabled ? (active ? 1.0 : 0.1) : 0.03
    
    scale: tapHandler.pressed ? 0.92 : (hoverHandler.hovered ? 1.05 : 1.0)
    Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
    Behavior on color { ColorAnimation { duration: 250 } }
    Behavior on opacity { NumberAnimation { duration: 250 } }

    HoverHandler { id: hoverHandler; cursorShape: Qt.PointingHandCursor }

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: "white"
        opacity: hoverHandler.hovered ? 0.15 : 0.0
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: "transparent"
        border.color: "white"
        border.width: 1
        opacity: root.active ? 0.2 : 0.05
    }

    Text {
        id: iconText
        anchors.centerIn: parent
        
        anchors.horizontalCenterOffset: 1
        anchors.verticalCenterOffset: 1
        
        text: root.icon
        color: root.active ? "black" : "white"
        font.pixelSize: 20
        opacity: root.enabled ? (root.active ? 1.0 : 0.6) : 0.2
        renderType: Text.NativeRendering
    }
    
    Rectangle {
        anchors.centerIn: parent
        width: 24; height: 1.5; radius: 1
        color: "white"; opacity: 0.6
        rotation: 45
        visible: !root.enabled
    }

    TapHandler { 
        id: tapHandler
        enabled: root.enabled
        onTapped: root.clicked() 
    }
}
