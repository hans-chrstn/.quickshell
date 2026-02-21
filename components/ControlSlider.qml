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
    
    scale: mouseArea.pressed ? 0.98 : (mouseArea.containsMouse ? 1.02 : 1.0)
    Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: "transparent"
        border.color: "white"
        border.width: 1
        opacity: root.enabled ? 0.05 : 0.02
    }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: "white"
        opacity: root.enabled ? (mouseArea.containsMouse ? 0.12 : 0.08) : 0.02
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }

    ClippingRectangle {
        anchors.fill: parent
        radius: height / 2
        color: "transparent"
        visible: root.enabled

        Rectangle {
            anchors.left: parent.left
            height: parent.height
            width: parent.width * (mouseArea.pressed ? internalValue : root.value)
            color: root.barColor
            opacity: 0.95
            
            Behavior on width { 
                enabled: !mouseArea.pressed
                NumberAnimation { duration: 300; easing.type: Easing.OutExpo } 
            }
            
            Rectangle {
                anchors.top: parent.top
                width: parent.width; height: 1
                color: "white"; opacity: 0.2
            }
        }
    }

    property real internalValue: root.value

    Item {
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        width: 24; height: 24

        Text {
            anchors.centerIn: parent
            text: root.icon
            color: (root.enabled && (mouseArea.pressed ? internalValue : root.value) > 0.15) ? "black" : "white"
            font.pixelSize: 16
            opacity: root.enabled ? ( (mouseArea.pressed ? internalValue : root.value) > 0.15 ? 0.8 : 0.6) : 0.2
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        preventStealing: true
        cursorShape: Qt.PointingHandCursor
        
        function handleMove(mouse) {
            let nVal = Math.max(0, Math.min(1, mouse.x / width))
            root.internalValue = nVal
            root.moved(nVal)
        }
        
        onPressed: (mouse) => handleMove(mouse)
        onPositionChanged: (mouse) => {
            if (pressed) handleMove(mouse)
        }
    }
}
