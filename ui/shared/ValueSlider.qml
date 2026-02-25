import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.shared

Item {
    id: root
    
    property real sliderValue: 0.5
    property string sliderIcon: ""
    property color sliderBarColor: "white"
    property bool isSliderEnabled: true
    
    signal sliderMoved(real value)

    width: 180
    height: 32
    
    scale: interactionMouseArea.pressed ? 0.98 : (interactionMouseArea.containsMouse ? 1.02 : 1.0)
    Behavior on scale { 
        NumberAnimation { 
            duration: 300
            easing.type: Easing.OutExpo 
        } 
    }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: "transparent"
        border.color: "white"
        border.width: 1
        opacity: root.isSliderEnabled ? 0.05 : 0.02
    }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: "white"
        opacity: root.isSliderEnabled ? (interactionMouseArea.containsMouse ? 0.12 : 0.08) : 0.02
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }

    ClippingRectangle {
        anchors.fill: parent
        radius: height / 2
        color: "transparent"
        visible: root.isSliderEnabled

        Rectangle {
            anchors.left: parent.left
            height: parent.height
            width: parent.width * (interactionMouseArea.pressed ? internalTargetValue : root.sliderValue)
            color: root.sliderBarColor
            opacity: 0.95
            
            Behavior on width { 
                enabled: !interactionMouseArea.pressed
                NumberAnimation { 
                    duration: 300
                    easing.type: Easing.OutExpo 
                } 
            }
            
            Rectangle {
                anchors.top: parent.top
                width: parent.width
                height: 1
                color: "white"
                opacity: 0.2
            }
        }
    }

    property real internalTargetValue: root.sliderValue

    Item {
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        width: 24
        height: 24

        Text {
            anchors.centerIn: parent
            text: root.sliderIcon
            color: (root.isSliderEnabled && (interactionMouseArea.pressed ? internalTargetValue : root.sliderValue) > 0.15) ? "black" : "white"
            font.pixelSize: 16
            opacity: root.isSliderEnabled ? ((interactionMouseArea.pressed ? internalTargetValue : root.sliderValue) > 0.15 ? 0.8 : 0.6) : 0.2
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

    MouseArea {
        id: interactionMouseArea
        anchors.fill: parent
        enabled: root.isSliderEnabled
        hoverEnabled: true
        preventStealing: true
        cursorShape: Qt.PointingHandCursor
        
        function updateValue(mouse) {
            let newValue = MathUtils.clamp(mouse.x / width, 0, 1)
            root.internalTargetValue = newValue
            root.sliderMoved(newValue)
        }
        
        onPressed: (mouse) => updateValue(mouse)
        onPositionChanged: (mouse) => {
            if (pressed) updateValue(mouse)
        }
    }
}
