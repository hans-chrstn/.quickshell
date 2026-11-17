pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import "MediaTime.js" as MediaTime

Singleton {
    id: root

    property var consumers: ({})
    property string selectedPlayerId: ""
    readonly property var players: Mpris.players.values.filter(player => player.dbusName !== "org.mpris.MediaPlayer2.playerctld")
    readonly property var activePlayer: players.find(player => player.dbusName === selectedPlayerId) || players.find(player => player.isPlaying) || players[0] || null
    readonly property bool playing: activePlayer?.isPlaying === true
    readonly property int consumerCount: Object.keys(consumers).length
    readonly property real peak: peakMonitor.peak

    function setConsumer(id, enabled) {
        const key = String(id || "").trim();
        if (key.length === 0)
            return false;
        const next = Object.assign({}, consumers);
        if (enabled)
            next[key] = true;
        else
            delete next[key];
        consumers = next;
        return true;
    }

    function togglePlaying() {
        if (!activePlayer?.canTogglePlaying)
            return false;
        activePlayer.togglePlaying();
        return true;
    }

    function snapshot() {
        const player = activePlayer;
        return {
            selectedPlayerId: selectedPlayerId,
            activePlayerId: player?.dbusName || "",
            playing: playing,
            peak: peak,
            consumerCount: consumerCount,
            players: players.map(candidate => ({
                        id: candidate.dbusName,
                        identity: candidate.identity,
                        playing: candidate.isPlaying,
                        title: candidate.trackTitle,
                        artist: candidate.trackArtist,
                        album: candidate.trackAlbum,
                        length: candidate.lengthSupported ? candidate.length : null,
                        position: candidate.positionSupported ? candidate.position : null,
                        canTogglePlaying: candidate.canTogglePlaying,
                        canSeek: candidate.canSeek && candidate.positionSupported,
                        canGoPrevious: candidate.canGoPrevious,
                        canGoNext: candidate.canGoNext,
                        shuffleSupported: candidate.shuffleSupported,
                        loopSupported: candidate.loopSupported
                    }))
        };
    }

    function selectPlayer(id) {
        const player = players.find(candidate => candidate.dbusName === id);
        if (!player)
            return false;
        selectedPlayerId = player.dbusName;
        return true;
    }

    function previous() {
        if (!activePlayer?.canGoPrevious)
            return false;
        activePlayer.previous();
        return true;
    }

    function next() {
        if (!activePlayer?.canGoNext)
            return false;
        activePlayer.next();
        return true;
    }

    function seekTo(seconds) {
        const player = activePlayer;
        if (!player?.canSeek || !player.positionSupported || !player.lengthSupported || player.length <= 0)
            return false;
        const requested = Number(seconds);
        if (!Number.isFinite(requested))
            return false;
        player.seek(MediaTime.boundedSeconds(requested, player.length) - player.position);
        return true;
    }

    function seekBy(seconds) {
        const player = activePlayer;
        const requested = Number(seconds);
        if (!player?.canSeek || !Number.isFinite(requested))
            return false;
        player.seek(requested);
        return true;
    }

    function toggleShuffle() {
        const player = activePlayer;
        if (!player?.canControl || !player.shuffleSupported)
            return false;
        player.shuffle = !player.shuffle;
        return true;
    }

    function cycleRepeat() {
        const player = activePlayer;
        if (!player?.canControl || !player.loopSupported)
            return false;
        player.loopState = player.loopState === MprisLoopState.None ? MprisLoopState.Playlist : player.loopState === MprisLoopState.Playlist ? MprisLoopState.Track : MprisLoopState.None;
        return true;
    }

    PwNodePeakMonitor {
        id: peakMonitor
        node: Pipewire.defaultAudioSink
        enabled: root.playing && root.consumerCount > 0
    }
}
