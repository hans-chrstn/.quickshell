import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import qs.config

Item {
    id: root
    
    property string icon: ""
    property string label: ""
    property bool active: false
    property bool enabled: true
    property color activeColor: FrameConfig.accentColor
    
    signal clicked()
    signal longPressed()

    width: FrameConfig.controlCenterTileSize
    height: FrameConfig.controlCenterTileSize
    
    Rectangle {
        id: bg
        anchors.fill: parent
        radius: FrameConfig.controlCenterTileRadius
        color: active ? activeColor : "#FFFFFF"
        opacity: root.enabled ? (active ? 1.0 : 0.15) : 0.05
        
        Behavior on color { ColorAnimation { duration: 250 } }
        Behavior on opacity { NumberAnimation { duration: 250 } }
    }

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

    Text {
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
        onLongPressed: root.longPressed()
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.MiddleButton
        onClicked: (mouse) => { if (mouse.button === Qt.MiddleButton) root.longPressed() }
    }

    HoverHandler { id: hoverHandler; cursorShape: Qt.PointingHandCursor }
}
