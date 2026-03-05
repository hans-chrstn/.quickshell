pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    readonly property MprisPlayer activePlayer: {
        let players = Mpris.players.values
        if (players.length === 0) {
            return null
        }
        
        for (let i = 0; i < players.length; i++) {
            let player = players[i]
            if (player.playbackState === MprisPlaybackState.Playing && player.trackTitle !== "") {
                return player
            }
        }
        
        for (let i = 0; i < players.length; i++) {
            let player = players[i]
            if (player.playbackState === MprisPlaybackState.Playing) {
                return player
            }
        }
        
        for (let i = 0; i < players.length; i++) {
            let player = players[i]
            if (player.trackTitle !== "") {
                return player
            }
        }
        
        return players[0]
    }
}
