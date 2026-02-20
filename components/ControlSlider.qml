import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.config

Item {
    id: root
    
    property real value: 0.5
    property string icon: ""
    property color barColor: "white"
    property bool enabled: true
    
    signal moved(real val)

    width: 180; height: 32

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: "white"
        opacity: root.enabled ? 0.08 : 0.02
    }

    ClippingRectangle {
        anchors.fill: parent
        radius: height / 2
        color: "transparent"
        visible: root.enabled

        Rectangle {
            anchors.left: parent.left
            height: parent.height
            width: parent.width * root.value
            color: root.barColor
            opacity: 0.9
            
            Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
        }
    }

    Text {
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        text: root.icon
        color: root.value > 0.1 ? "black" : "white"
        font.pixelSize: 14
        opacity: root.enabled ? 1.0 : 0.3
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.enabled
        preventStealing: true
        
        function handleMove(mouse) {
            let nVal = mouse.x / width
            root.moved(Math.max(0, Math.min(1, nVal)))
        }
        
        onPressed: (mouse) => handleMove(mouse)
        onPositionChanged: (mouse) => handleMove(mouse)
    }
}
