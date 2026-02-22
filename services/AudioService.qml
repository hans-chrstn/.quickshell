pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

Singleton {
    id: root

    property bool hasAudio: !!sink

    readonly property PwNode sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: [root.sink] }

    readonly property real volume: (sink && sink.ready && sink.audio) ? sink.audio.volume : 0.0
    readonly property bool muted: (sink && sink.ready && sink.audio) ? sink.audio.muted : false
    
    property real lastVolume: 0.5

    function setVolume(val: real): void {
        if (sink && sink.ready && sink.audio) {
            let v = Math.max(0, Math.min(1, val))
            if (v === 0 && root.volume > 0) root.lastVolume = root.volume
            sink.audio.muted = (v === 0); sink.audio.volume = v
        }
    }
}
