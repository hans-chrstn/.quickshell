pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs.components
import qs.utilities

Singleton {
    id: root

    property bool isWpctlAvailable: false
    property bool isPactlAvailable: false
    readonly property bool areAudioToolsAvailable: isWpctlAvailable || isPactlAvailable
    
    property bool isAudioAvailable: !!defaultSink && areAudioToolsAvailable

    readonly property PwNode defaultSink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: [root.defaultSink] }

    readonly property real volume: (defaultSink && defaultSink.ready && defaultSink.audio) ? defaultSink.audio.volume : 0.0
    readonly property bool isMuted: (defaultSink && defaultSink.ready && defaultSink.audio) ? defaultSink.audio.muted : false
    
    property real previousVolume: 0.5

    function setVolume(value) {
        if (!isAudioAvailable) return
        
        if (defaultSink && defaultSink.ready && defaultSink.audio) {
            let clampedValue = MathUtils.clamp(value, 0, 1)
            if (clampedValue === 0 && root.volume > 0) root.previousVolume = root.volume
            defaultSink.audio.muted = (clampedValue === 0); defaultSink.audio.volume = clampedValue
        }
    }

    DependencyChecker {
        binaryName: "wpctl"
        onIsAvailableChanged: root.isWpctlAvailable = isAvailable
    }

    DependencyChecker {
        binaryName: "pactl"
        onIsAvailableChanged: root.isPactlAvailable = isAvailable
    }
}
