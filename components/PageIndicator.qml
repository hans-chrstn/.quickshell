import QtQuick
import qs.config

Row {
    id: root
    
    property int count: 0
    property int currentIndex: 0
    property color color: "white"
    property int dotSize: 4
    property int activeDotWidth: 12

    anchors.horizontalCenter: parent.horizontalCenter
    spacing: FrameConfig.indicatorRowSpacing

    Repeater { 
        model: root.count
        Rectangle { 
            width: root.currentIndex === index ? root.activeDotWidth : root.dotSize
            height: root.dotSize
            radius: root.dotSize / 2
            color: root.color
            opacity: root.currentIndex === index ? 0.8 : 0.2
            
            Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
            Behavior on opacity { NumberAnimation { duration: 300 } }
        } 
    }
}
