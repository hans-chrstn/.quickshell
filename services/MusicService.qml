pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    readonly property var activePlayer: {
        if (Mpris.players.values.length === 0) return null
        
        for (let i = 0; i < Mpris.players.values.length; i++) {
            if (Mpris.players.values[i].playbackState === MprisPlaybackState.Playing) {
                return Mpris.players.values[i]
            }
        }
        
        return Mpris.players.values[0]
    }
}
