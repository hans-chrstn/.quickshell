pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs.components

Singleton {
    id: root

    property bool hasWpctl: false
    property bool hasPactl: false
    readonly property bool hasAudioTools: hasWpctl || hasPactl
    
    property bool hasAudio: !!sink && hasAudioTools

    readonly property PwNode sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: [root.sink] }

    readonly property real volume: (sink && sink.ready && sink.audio) ? sink.audio.volume : 0.0
    readonly property bool muted: (sink && sink.ready && sink.audio) ? sink.audio.muted : false
    
    property real lastVolume: 0.5

    function setVolume(val: real): void {
        if (!hasAudio) return
        
        if (sink && sink.ready && sink.audio) {
            let v = Math.max(0, Math.min(1, val))
            if (v === 0 && root.volume > 0) root.lastVolume = root.volume
            sink.audio.muted = (v === 0); sink.audio.volume = v
        }
    }

    AvailabilityCheck {
        binary: "wpctl"
        onExistsChanged: root.hasWpctl = exists
    }

    AvailabilityCheck {
        binary: "pactl"
        onExistsChanged: root.hasPactl = exists
    }
}
