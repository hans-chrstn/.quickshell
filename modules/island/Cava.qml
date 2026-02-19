import QtQuick
import Quickshell
import qs.config

Item {
    id: root
    anchors.fill: parent
    opacity: FrameConfig.cavaOpacity
    
    property int barCount: FrameConfig.cavaBarCount
    property color barColor: FrameConfig.accentColor
    
    property var currentHeights: []
    property var targetHeights: []
    
    Component.onCompleted: {
        for (var i = 0; i < barCount; i++) {
            currentHeights.push(0);
            targetHeights.push(0);
        }
    }

    Timer {
        id: targetTimer
        interval: 150
        running: root.visible
        repeat: true
        onTriggered: {
            for (var i = 0; i < barCount; i++) {
                targetHeights[i] = root.height * (0.1 + (0.8 * Math.random()));
            }
        }
    }

    FrameAnimation {
        running: root.visible
        onTriggered: {
            if (currentHeights.length < barCount) return;
            for (var i = 0; i < barCount; i++) {
                currentHeights[i] += (targetHeights[i] - currentHeights[i]) * 0.15;
                var item = repeater.itemAt(i);
                if (item) item.height = currentHeights[i];
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
                height: 0
            }
        }
    }
}