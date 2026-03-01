import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import qs.core

Item {
    id: root
    
    anchors.fill: parent
    opacity: ThemeManager.cavaOpacity
    
    property int visualizerBarCount: ThemeManager.cavaBarCount
    property color visualizerBarColor: ThemeManager.accentColor
    
    property var barHeights: []
    property var targetBarHeights: []
    
    readonly property bool isMusicPlaying: {
        for (let i = 0; i < Mpris.players.values.length; i++) {
            if (Mpris.players.values[i].playbackState === MprisPlaybackState.Playing) {
                return true
            }
        }
        return false
    }

    Component.onCompleted: {
        for (let i = 0; i < visualizerBarCount; i++) {
            barHeights.push(0)
            targetBarHeights.push(0)
        }
    }

    Timer {
        id: targetHeightUpdateTimer
        interval: ThemeManager.cavaUpdateInterval
        running: root.visible && root.isMusicPlaying
        repeat: true
        onTriggered: {
            let currentVolume = AudioManager.volume
            let volumeScale = currentVolume > 0 ? Math.pow(currentVolume, 0.4) : 0
            
            for (let i = 0; i < visualizerBarCount; i++) {
                let centerBias = 1.0 - Math.abs((i - visualizerBarCount / 2) / (visualizerBarCount / 2)) * 0.4
                let randomFactor = 0.4 + (0.6 * Math.random())
                
                let floorHeight = root.height * 0.15 * randomFactor
                let dynamicHeight = root.height * 0.85 * volumeScale * centerBias * randomFactor
                
                targetBarHeights[i] = floorHeight + dynamicHeight
            }
        }
    }
    
    onIsMusicPlayingChanged: {
        if (!isMusicPlaying) {
            for (let i = 0; i < visualizerBarCount; i++) {
                targetBarHeights[i] = 2
            }
        }
    }

    FrameAnimation {
        running: root.visible
        onTriggered: {
            if (barHeights.length < visualizerBarCount) return
            for (let i = 0; i < visualizerBarCount; i++) {
                barHeights[i] += (targetBarHeights[i] - barHeights[i]) * ThemeManager.cavaSmoothing
                let barItem = visualizerBarRepeater.itemAt(i)
                if (barItem) {
                    barItem.height = Math.max(2, barHeights[i])
                }
            }
        }
    }

    Row {
        anchors.fill: parent
        spacing: ThemeManager.cavaSpacing
        
        Repeater {
            id: visualizerBarRepeater
            model: root.visualizerBarCount
            
            delegate: Rectangle {
                width: (parent.width - (root.visualizerBarCount - 1) * parent.spacing) / root.visualizerBarCount
                radius: width / 2
                color: root.visualizerBarColor
                anchors.verticalCenter: parent.verticalCenter
                height: 0
            }
        }
    }
}
