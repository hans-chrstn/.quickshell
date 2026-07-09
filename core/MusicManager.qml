pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    property string preferredPlayerName: ""
    property var recentTracks: []
    property int _manualCycleIndex: -1
    
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
    
    function cyclePlayers() {
        let players = Mpris.players.values
        if (players.length <= 1) return
        
        let currentIndex = -1
        for (let i = 0; i < players.length; i++) {
            if (activePlayer && (players[i].name === activePlayer.name)) {
                currentIndex = i
                break
            }
        }
        
        let nextIndex = (currentIndex + 1) % players.length
        root.selectPlayer(players[nextIndex])
    }
    
    property string _lastTrackInfo: ""
    
    onActivePlayerChanged: {
        _checkTrackChange()
    }
    
    Connections {
        target: root.activePlayer
        ignoreUnknownSignals: true
        function onTrackTitleChanged() { root._checkTrackChange() }
        function onTrackArtistChanged() { root._checkTrackChange() }
    }
    
    function _checkTrackChange() {
        if (!root.activePlayer || !root.activePlayer.trackTitle) return
        let info = (root.activePlayer.trackArtist || "Unknown") + " - " + root.activePlayer.trackTitle
        if (info !== root._lastTrackInfo) {
            root._lastTrackInfo = info
            let newHistory = [info]
            for (let i = 0; i < root.recentTracks.length && i < 19; i++) {
                if (root.recentTracks[i] !== info) {
                    newHistory.push(root.recentTracks[i])
                }
            }
            root.recentTracks = newHistory
        }
    }
}
