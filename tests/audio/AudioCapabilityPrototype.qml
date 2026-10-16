import QtQuick
import QtQml.Models
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../../services/audio/AudioNodeModel.js" as AudioNodeModel

ShellRoot {
    id: root

    property var audioNodes: []
    property var latestSnapshot: ({})
    property int revision: 0

    function scheduleSnapshot() {
        snapshotDebounce.restart();
    }

    function synchronizeNodes() {
        audioNodes = (Pipewire.nodes?.values || []).filter(node => !!node?.audio);
        mutationProbe.handleNodesChanged();
        scheduleSnapshot();
    }

    function channelNames(node) {
        const channels = [];
        for (const channel of node?.audio?.channels || [])
            channels.push(PwAudioChannel.toString(channel));
        return channels;
    }

    function rawNode(node) {
        const defaultOutput = Pipewire.defaultAudioSink;
        const defaultInput = Pipewire.defaultAudioSource;
        const preferredOutput = Pipewire.preferredDefaultAudioSink;
        const preferredInput = Pipewire.preferredDefaultAudioSource;
        return {
            id: node?.id ?? 0,
            type: Number(node?.type ?? 0),
            name: node?.name ?? "",
            description: node?.description ?? "",
            nickname: node?.nickname ?? "",
            properties: node?.properties ?? ({}),
            ready: !!node?.ready,
            isStream: !!node?.isStream,
            isSink: !!node?.isSink,
            hasAudio: !!node?.audio,
            volume: node?.ready && node?.audio ? node.audio.volume : null,
            muted: node?.ready && node?.audio ? node.audio.muted : null,
            channels: node?.ready ? channelNames(node) : [],
            isDefault: node === defaultOutput || node === defaultInput,
            isPreferredDefault: node === preferredOutput || node === preferredInput
        };
    }

    function compactNode(node) {
        if (!node)
            return null;
        return {
            id: node.id,
            name: String(node.description || node.nickname || node.name || ""),
            ready: !!node.ready
        };
    }

    function linkRecords() {
        const records = [];
        for (const link of Pipewire.linkGroups?.values || []) {
            if (!link?.source?.audio || !link?.target?.audio)
                continue;
            records.push({
                sourceId: link.source.id,
                targetId: link.target.id
            });
        }
        records.sort((left, right) => left.sourceId - right.sourceId || left.targetId - right.targetId);
        return records;
    }

    function buildSnapshot() {
        const nodes = AudioNodeModel.normalizedNodes(audioNodes.map(node => rawNode(node)));
        return {
            backend: "quickshell-pipewire",
            ready: Pipewire.ready,
            eventDriven: true,
            pollingIntervalMs: 0,
            revision: revision,
            trackedNodeCount: audioNodes.length,
            roleCounts: AudioNodeModel.roleCounts(nodes),
            defaults: {
                output: compactNode(Pipewire.defaultAudioSink),
                input: compactNode(Pipewire.defaultAudioSource),
                preferredOutput: compactNode(Pipewire.preferredDefaultAudioSink),
                preferredInput: compactNode(Pipewire.preferredDefaultAudioSource)
            },
            nodes: nodes,
            links: linkRecords(),
            capabilityMatrix: {
                nodeEnumeration: "native",
                linkObservation: "native",
                defaultObservation: "native",
                preferredDefaultWrite: mutationProbe.evidence.outputDefault && mutationProbe.evidence.inputDefault ? "native-proven-current-session" : "native-api-present-not-yet-exercised",
                volumeMuteWrite: mutationProbe.evidence.volume && mutationProbe.evidence.mute ? "native-proven-current-session" : "native-api-present-not-yet-exercised",
                streamRoutingWrite: "not-exposed-by-current-quickshell-api",
                devicePortsProfiles: "not-exposed-by-current-quickshell-api",
                naturalBaseVolume: "not-exposed-by-current-quickshell-api"
            },
            mutationProbe: mutationProbe.snapshot()
        };
    }

    function publishSnapshot() {
        revision += 1;
        latestSnapshot = buildSnapshot();
        console.log("AUDIO_CAPABILITY_SNAPSHOT:" + JSON.stringify(latestSnapshot));
    }

    Component.onCompleted: {
        if (Pipewire.ready)
            synchronizeNodes();
        else
            scheduleSnapshot();
    }

    Connections {
        target: Pipewire

        function onReadyChanged() {
            if (Pipewire.ready)
                root.synchronizeNodes();
            else {
                root.audioNodes = [];
                root.scheduleSnapshot();
            }
        }

        function onDefaultAudioSinkChanged() {
            root.scheduleSnapshot();
        }

        function onDefaultAudioSourceChanged() {
            root.scheduleSnapshot();
        }

        function onDefaultConfiguredAudioSinkChanged() {
            root.scheduleSnapshot();
        }

        function onDefaultConfiguredAudioSourceChanged() {
            root.scheduleSnapshot();
        }
    }

    Connections {
        target: Pipewire.nodes

        function onValuesChanged() {
            root.synchronizeNodes();
        }
    }

    Connections {
        target: Pipewire.linkGroups

        function onValuesChanged() {
            root.scheduleSnapshot();
        }
    }

    PwObjectTracker {
        objects: root.audioNodes
    }

    Instantiator {
        model: root.audioNodes

        delegate: QtObject {
            id: watcher

            required property var modelData

            property Connections nodeChanges: Connections {
                target: watcher.modelData

                function onPropertiesChanged() {
                    root.scheduleSnapshot();
                }

                function onReadyChanged() {
                    root.scheduleSnapshot();
                }
            }

            property Connections audioChanges: Connections {
                target: watcher.modelData?.audio ?? null

                function onChannelsChanged() {
                    root.scheduleSnapshot();
                }

                function onMutedChanged() {
                    root.scheduleSnapshot();
                }

                function onVolumesChanged() {
                    root.scheduleSnapshot();
                }
            }
        }
    }

    Timer {
        id: snapshotDebounce

        interval: 80
        onTriggered: root.publishSnapshot()
    }

    AudioMutationProbe {
        id: mutationProbe

        nodes: root.audioNodes
        onStatePublished: root.scheduleSnapshot()
    }

    IpcHandler {
        target: "audio-capability"

        function status(): string {
            return JSON.stringify(root.buildSnapshot(), null, 2);
        }

        function probeStatus(): string {
            return JSON.stringify(mutationProbe.snapshot(), null, 2);
        }

        function probeVolume(nodeId: int): string {
            return JSON.stringify(mutationProbe.probeVolume(nodeId), null, 2);
        }

        function probeMute(nodeId: int): string {
            return JSON.stringify(mutationProbe.probeMute(nodeId), null, 2);
        }

        function probeDefault(role: string, nodeId: int): string {
            return JSON.stringify(mutationProbe.probeDefault(role, nodeId), null, 2);
        }

        function restoreProbe(): string {
            return JSON.stringify(mutationProbe.restoreNow(), null, 2);
        }
    }
}
