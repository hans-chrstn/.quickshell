import QtQuick
import qs.config

Item {
    id: root
    anchors.fill: parent
    opacity: FrameConfig.cavaOpacity
    
    property int barCount: FrameConfig.cavaBarCount
    property color barColor: FrameConfig.accentColor
    
    Timer {
        id: mainTimer
        interval: FrameConfig.cavaUpdateInterval
        running: root.visible
        repeat: true
        onTriggered: {
            for (var i = 0; i < barCount; i++) {
                repeater.itemAt(i).targetHeight = root.height * (0.1 + (0.8 * Math.random()));
            }
        }
    }

    Row {
        anchors.fill: parent
        spacing: FrameConfig.cavaSpacing
        
        Repeater {
            id: repeater
            model: root.barCount
            
            delegate: Rectangle {
                width: (parent.width - (root.barCount - 1) * parent.spacing) / root.barCount
                radius: width / 2
                color: root.barColor
                anchors.verticalCenter: parent.verticalCenter
                
                property real targetHeight: 0
                height: targetHeight
                
                Behavior on height {
                    NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                }
            }
        }
    }
}