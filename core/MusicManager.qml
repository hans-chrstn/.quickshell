pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    readonly property MprisPlayer activePlayer: {
        if (Mpris.players.values.length === 0) return null
        
        for (let i = 0; i < Mpris.players.values.length; i++) {
            let player = Mpris.players.values[i]
            if (player.playbackState === MprisPlaybackState.Playing) {
                return player
            }
        }
        
        return Mpris.players.values[0]
    }
}
