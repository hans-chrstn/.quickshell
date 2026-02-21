import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import qs.config
import qs.services

Item {
    id: root
    anchors.fill: parent
    opacity: FrameConfig.cavaOpacity
    
    property int barCount: FrameConfig.cavaBarCount
    property color barColor: FrameConfig.accentColor
    
    property var currentHeights: []
    property var targetHeights: []
    
    property bool isPlaying: {
        for (var i = 0; i < Mpris.players.values.length; i++) {
            if (Mpris.players.values[i].playbackState === MprisPlaybackState.Playing) return true;
        }
        return false;
    }

    Component.onCompleted: {
        for (var i = 0; i < barCount; i++) {
            currentHeights.push(0);
            targetHeights.push(0);
        }
    }

    Timer {
        id: targetTimer
        interval: FrameConfig.cavaUpdateInterval
        running: root.visible && root.isPlaying
        repeat: true
        onTriggered: {
            var volume = SystemControl.volume
            var volumeScale = volume > 0 ? Math.pow(volume, 0.4) : 0
            
            for (var i = 0; i < barCount; i++) {
                var centerBias = 1.0 - Math.abs((i - barCount / 2) / (barCount / 2)) * 0.4
                var randomFactor = 0.4 + (0.6 * Math.random())
                
                var floorHeight = root.height * 0.15 * randomFactor
                var dynamicHeight = root.height * 0.85 * volumeScale * centerBias * randomFactor
                
                targetHeights[i] = floorHeight + dynamicHeight
            }
        }
    }
    
    onIsPlayingChanged: {
        if (!isPlaying) {
            for (var i = 0; i < barCount; i++) targetHeights[i] = 2;
        }
    }

    FrameAnimation {
        running: root.visible
        onTriggered: {
            if (currentHeights.length < barCount) return;
            for (var i = 0; i < barCount; i++) {
                currentHeights[i] += (targetHeights[i] - currentHeights[i]) * FrameConfig.cavaSmoothing;
                var item = repeater.itemAt(i);
                if (item) item.height = Math.max(2, currentHeights[i]);
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
