import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import qs.core
import qs.ui.shared.effects

Item {
    id: root
    
    anchors.fill: parent

    readonly property bool isMusicPlaying: {
        if (!Mpris.players || !Mpris.players.values) return false
        for (let i = 0; i < Mpris.players.values.length; i++) {
            if (Mpris.players.values[i].playbackState === MprisPlaybackState.Playing) {
                return true
            }
        }
        return false
    }

    LiquidVisualizer {
        id: visualizer
        anchors.fill: parent
        intensity: root.isMusicPlaying ? Math.pow(AudioManager.volume, 0.45) : 0.0
        baseColor: ThemeManager.accentColor
        visible: root.isMusicPlaying || intensity > 0.01
    }
}
