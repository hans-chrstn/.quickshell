pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs.ui.shared
import qs.shared

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

    property ListModel sinkModel: ListModel { }
    readonly property alias sinks: root.sinkModel

    function updateSinks() {
        if (!Pipewire.ready) return

        let nodes = Pipewire.nodes.values
        let foundSinks = []
        let currentId = defaultSink ? defaultSink.id : -1

        for (let i = 0; i < nodes.length; i++) {
            let node = nodes[i]
            if (!node) continue

            let type = node.type
            let isAudio = (type & PwNodeType.Audio) !== 0
            let isSink = (type & PwNodeType.Sink) !== 0
            let isStream = (type & PwNodeType.Stream) !== 0
            
            if (isAudio && isSink && !isStream && node.id !== currentId) {
                foundSinks.push({
                    "node": node,
                    "name": node.description || node.name || "Unknown Device",
                    "id": node.id
                })
            }
        }

        if (foundSinks.length !== sinkModel.count) {
            sinkModel.clear()
            for (let sink of foundSinks) {
                sinkModel.append(sink)
            }
        } else {
            let changed = false
            for (let i = 0; i < foundSinks.length; i++) {
                if (sinkModel.get(i).id !== foundSinks[i].id) {
                    changed = true
                    break
                }
            }
            if (changed) {
                sinkModel.clear()
                for (let sink of foundSinks) {
                    sinkModel.append(sink)
                }
            }
        }
    }

    function selectSink(node) {
        if (node) {
            Pipewire.preferredDefaultAudioSink = node
            Qt.callLater(() => { root.updateSinks() })
        }
    }

    function setVolume(value) {
        if (!isAudioAvailable) return
        
        if (defaultSink && defaultSink.ready && defaultSink.audio) {
            let clampedValue = MathUtils.clamp(value, 0, 1)
            if (clampedValue === 0 && root.volume > 0) root.previousVolume = root.volume
            defaultSink.audio.muted = (clampedValue === 0)
            defaultSink.audio.volume = clampedValue
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

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.updateSinks()
    }

    Connections {
        target: Pipewire
        function onReadyChanged() { if (Pipewire.ready) root.updateSinks() }
        function onDefaultAudioSinkChanged() { root.updateSinks() }
    }
}
