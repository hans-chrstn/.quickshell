pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    property string preferredPlayerName: ""
    
    readonly property var activePlayer: {
        let players = Mpris.players.values
        if (players.length === 0) {
            return null
        }

        if (root.preferredPlayerName !== "") {
            for (let i = 0; i < players.length; i++) {
                let player = players[i]
                if (player && (player.name === root.preferredPlayerName || player.identity === root.preferredPlayerName)) {
                    return player
                }
            }
        }

        for (let i = 0; i < players.length; i++) {
            let player = players[i]
            if (player && player.playbackState === MprisPlaybackState.Playing && (player.trackTitle || "") !== "") {
                return player
            }
        }
        
        for (let i = 0; i < players.length; i++) {
            let player = players[i]
            if (player && player.playbackState === MprisPlaybackState.Playing) {
                return player
            }
        }
        
        for (let i = 0; i < players.length; i++) {
            let player = players[i]
            if (player && (player.trackTitle || "") !== "") {
                return player
            }
        }
        
        return players[0] || null
    }

    function selectPlayer(player) {
        if (!player) return
        root.preferredPlayerName = player.identity || player.name
    }
}
