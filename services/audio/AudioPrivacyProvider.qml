import QtQuick
import QtQml.Models
import Quickshell.Services.Pipewire
import "AudioNodeModel.js" as AudioNodeModel
import "AudioPrivacyModel.js" as AudioPrivacyModel

QtObject {
    id: root

    property var candidateNodes: []
    property var records: []
    property var links: []
    property var state: AudioPrivacyModel.snapshot([], [], false)
    property int revision: 0
    readonly property bool ready: Pipewire.ready

    function isBaseCandidate(node) {
        const type = Number(node?.type || 0);
        return (type & 4) === 4 || (type & 8) === 8 || node?.isStream === true;
    }

    function synchronizeNodes() {
        const allNodes = Pipewire.nodes?.values || [];
        const baseNodes = allNodes.filter(node => isBaseCandidate(node));
        const baseRecords = AudioNodeModel.normalizedNodes(baseNodes.map(node => rawNode(node)));
        const linkedSourceIds = new Set(AudioPrivacyModel.linkedSourceIds(baseRecords, linkRecords()));
        candidateNodes = allNodes.filter(node => isBaseCandidate(node) || linkedSourceIds.has(Number(node?.id || 0)));
        schedulePublish();
    }

    function channelNames(node) {
        const result = [];
        for (const channel of node?.audio?.channels || [])
            result.push(PwAudioChannel.toString(channel));
        return result;
    }

    function rawNode(node) {
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
            isDefault: node === Pipewire.defaultAudioSink || node === Pipewire.defaultAudioSource,
            isPreferredDefault: node === Pipewire.preferredDefaultAudioSink || node === Pipewire.preferredDefaultAudioSource
        };
    }

    function linkRecords() {
        const result = [];
        for (const link of Pipewire.linkGroups?.values || []) {
            const sourceId = Number(link?.source?.id || 0);
            const targetId = Number(link?.target?.id || 0);
            if (sourceId <= 0 || targetId <= 0)
                continue;
            result.push({
                sourceId: sourceId,
                targetId: targetId
            });
        }
        result.sort((left, right) => left.sourceId - right.sourceId || left.targetId - right.targetId);
        return result;
    }

    function publish() {
        records = AudioNodeModel.normalizedNodes(candidateNodes.map(node => rawNode(node)));
        links = linkRecords();
        state = AudioPrivacyModel.snapshot(records, links, ready);
        revision += 1;
    }

    function schedulePublish() {
        publishDebounce.restart();
    }

    function snapshot() {
        return {
            backend: "quickshell-pipewire",
            ready: ready,
            eventDriven: true,
            pollingIntervalMs: 0,
            revision: revision,
            trackedNodeCount: candidateNodes.length,
            captureActive: state.captureActive,
            microphoneActive: state.microphoneActive,
            monitorCaptureActive: state.monitorCaptureActive,
            unknownCaptureActive: state.unknownCaptureActive,
            clientCount: state.clientCount,
            sourceCount: state.sourceCount,
            pathCount: state.pathCount,
            clients: state.clients,
            sources: state.sources,
            paths: state.paths
        };
    }

    Component.onCompleted: {
        if (Pipewire.ready)
            synchronizeNodes();
        else
            schedulePublish();
    }

    property Connections pipewireChanges: Connections {
        target: Pipewire

        function onReadyChanged() {
            if (Pipewire.ready)
                root.synchronizeNodes();
            else {
                root.candidateNodes = [];
                root.schedulePublish();
            }
        }
    }

    property Connections nodeCollectionChanges: Connections {
        target: Pipewire.nodes

        function onValuesChanged() {
            root.synchronizeNodes();
        }
    }

    property Connections linkCollectionChanges: Connections {
        target: Pipewire.linkGroups

        function onValuesChanged() {
            root.synchronizeNodes();
        }
    }

    property PwObjectTracker tracker: PwObjectTracker {
        objects: root.candidateNodes
    }

    property Instantiator nodeWatchers: Instantiator {
        model: root.candidateNodes

        delegate: QtObject {
            id: watcher

            required property var modelData

            property Connections changes: Connections {
                target: watcher.modelData

                function onPropertiesChanged() {
                    root.schedulePublish();
                }

                function onReadyChanged() {
                    root.schedulePublish();
                }
            }
        }
    }

    property Timer publishDebounce: Timer {
        interval: 50
        onTriggered: root.publish()
    }
}
