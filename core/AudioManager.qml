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
    readonly property PwNode defaultSource: Pipewire.defaultAudioSource
    
    PwObjectTracker { 
        id: sinkTracker
        objects: root.defaultSink ? [root.defaultSink] : [] 
    }
    
    PwObjectTracker {
        id: sourceTracker
        objects: root.defaultSource ? [root.defaultSource] : []
    }

    readonly property real volume: (defaultSink && defaultSink.ready && defaultSink.audio) ? defaultSink.audio.volume : 0.0
    readonly property bool isMuted: (defaultSink && defaultSink.ready && defaultSink.audio) ? defaultSink.audio.muted : false
    
    property real previousVolume: 0.5

    property ListModel sinkModel: ListModel { }
    readonly property alias sinks: root.sinkModel

    property ListModel sourceModel: ListModel { }
    readonly property alias sources: root.sourceModel

    property ListModel streamModel: ListModel { }
    readonly property alias streams: root.streamModel
    
    property ListModel sourceStreamModel: ListModel { }
    readonly property alias sourceStreams: root.sourceStreamModel

    property var pidsPlayingAudio: []
    property var appNamesPlayingAudio: []

    function updateNodes() {
        if (!Pipewire.ready) return

        let nodes = Pipewire.nodes.values
        let foundSinks = []
        let foundSources = []
        let foundStreams = []
        let foundSourceStreams = []
        let foundPids = []
        let foundAppNames = []

        for (let i = 0; i < nodes.length; i++) {
            let node = nodes[i]
            if (!node || node.id === undefined) continue

            let type = node.type
            let isAudio = (type & PwNodeType.Audio) !== 0
            let isSink = (type & PwNodeType.Sink) !== 0
            let isSource = (type & PwNodeType.Source) !== 0
            let isStream = (type & PwNodeType.Stream) !== 0
            
            if (isAudio && isSink && !isStream) {
                foundSinks.push({
                    "id": node.id,
                    "name": node.description || node.name || "Unknown Output",
                    "nodeObj": node
                })
            } else if (isAudio && isSource && !isStream) {
                foundSources.push({
                    "id": node.id,
                    "name": node.description || node.name || "Unknown Input",
                    "nodeObj": node
                })
            } else if (isAudio && isStream && node.audio) {
                let streamData = {
                    "id": node.id,
                    "name": node.description || node.name || "Application",
                    "nodeObj": node
                }
                
                foundStreams.push(streamData)
                
                let pid = node.properties["application.process.id"]
                if (pid) {
                    let pidInt = parseInt(pid)
                    if (!isNaN(pidInt) && !foundPids.includes(pidInt)) {
                        foundPids.push(pidInt)
                    }
                }

                let names = [
                    node.properties["application.name"],
                    node.properties["node.name"],
                    node.description,
                    node.name
                ]
                for (let n of names) {
                    if (n) {
                        let cn = n.toLowerCase()
                        if (!foundAppNames.includes(cn)) foundAppNames.push(cn)
                    }
                }
            }
        }

        root.pidsPlayingAudio = foundPids
        root.appNamesPlayingAudio = foundAppNames
        root._syncModel(sinkModel, foundSinks)
        root._syncModel(sourceModel, foundSources)
        root._syncModel(streamModel, foundStreams)
        root._syncModel(sourceStreamModel, foundSourceStreams)
    }

    function _syncModel(model, data) {
        if (data.length !== model.count) {
            model.clear()
            for (let item of data) {
                model.append(item)
            }
        } else {
            let changed = false
            for (let i = 0; i < data.length; i++) {
                if (model.get(i).id !== data[i].id) {
                    changed = true; break
                }
            }
            if (changed) {
                model.clear()
                for (let item of data) {
                    model.append(item)
                }
            }
        }
    }

    function selectSink(node) {
        if (node) {
            Pipewire.preferredDefaultAudioSink = node
            Qt.callLater(() => { root.updateNodes() })
        }
    }
    
    function selectSource(node) {
        if (node) {
            Pipewire.preferredDefaultAudioSource = node
            Qt.callLater(() => { root.updateNodes() })
        }
    }

    function setVolume(value) {
        if (!isAudioAvailable) return
        
        if (defaultSink && defaultSink.ready && defaultSink.audio) {
            let clampedValue = MathUtils.clamp(value, 0, 1)
            
            if (clampedValue === 0 && root.volume > 0) root.previousVolume = root.volume
            
            if (Math.abs(defaultSink.audio.volume - clampedValue) > 0.001) {
                if (defaultSink.audio.muted && clampedValue > 0) {
                    defaultSink.audio.muted = false
                }
                defaultSink.audio.volume = clampedValue
            }
            
            if (clampedValue === 0 && !defaultSink.audio.muted) {
                defaultSink.audio.muted = true
            }
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
        id: updateTimer
        interval: 3000
        running: Pipewire.ready
        repeat: true
        triggeredOnStart: true
        onTriggered: root.updateNodes()
    }

    Connections {
        target: Pipewire
        function onReadyChanged() { if (Pipewire.ready) root.updateNodes() }
        function onDefaultAudioSinkChanged() { root.updateNodes() }
        function onDefaultAudioSourceChanged() { root.updateNodes() }
    }
}
