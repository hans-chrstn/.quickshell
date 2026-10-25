import QtQuick
import QtQml.Models
import Quickshell.Services.Pipewire
import "AudioApplicationControlModel.js" as AudioApplicationControlModel
import "AudioApplicationModel.js" as AudioApplicationModel
import "AudioNodeModel.js" as AudioNodeModel

Item {
    id: root

    property var audioNodes: []
    property var nodes: []
    property var retainedOrder: []
    property var links: []
    property var defaults: ({})
    property var routePolicies: ({})
    property var applications: AudioApplicationModel.groupedApplications([])
    property var roleCounts: AudioNodeModel.roleCounts([])
    property int revision: 0
    property bool connectionTimedOut: false
    readonly property bool ready: Pipewire.ready
    readonly property var providerError: connectionTimedOut ? ({
            code: "pipewire-unavailable",
            message: "PipeWire did not become ready within the bounded connection window"
        }) : ({})
    readonly property var outputSelection: defaultCoordinator.outputState
    readonly property var inputSelection: defaultCoordinator.inputState
    readonly property var outputTransition: hotplugCoordinator.outputTransition
    readonly property var inputTransition: hotplugCoordinator.inputTransition
    readonly property bool routeBusy: routeProvider.busy
    readonly property var routeTargets: routeProvider.targets
    readonly property var routeDiagnostics: routeProvider.diagnostics()
    readonly property var routePolicyDiagnostics: routePolicyCoordinator.diagnostics()
    signal deviceTransitionOccurred(var transition)
    signal applicationRouteResultOccurred(var result)

    visible: false
    width: 0
    height: 0

    function schedulePublish() {
        publishDebounce.restart();
    }

    function setPreferredDefault(role, stableKey) {
        return defaultCoordinator.request(role, stableKey);
    }

    function setApplicationRoute(groupKey, targetStableKey) {
        return routeProvider.request(groupKey, targetStableKey);
    }

    function applicationControlResult(accepted, code, message, request, streamCount) {
        return {
            accepted: accepted,
            code: code,
            message: message,
            groupKey: String(request?.groupKey || ""),
            sessionId: String(request?.sessionId || ""),
            operation: String(request?.operation || ""),
            streamCount: Math.max(0, Number(streamCount) || 0),
            revision: revision
        };
    }

    function applyApplicationState(request) {
        if (!ready)
            return applicationControlResult(false, "backend-unavailable", "PipeWire is not ready.", request, 0);
        const target = AudioApplicationControlModel.controlTarget(applications, request?.groupKey, request?.operation);
        if (!target.accepted)
            return applicationControlResult(false, target.code, target.message, request, 0);
        const continuity = AudioApplicationControlModel.targetContinuity(target.group, request);
        if (!continuity.accepted)
            return applicationControlResult(false, continuity.code, continuity.message, request, 0);

        const volume = Number(request?.volume);
        const muted = request?.muted;
        if (!Number.isFinite(volume) || typeof muted !== "boolean")
            return applicationControlResult(false, "invalid-state", "The requested application sound state is invalid.", request, 0);

        const nativeById = ({});
        for (const node of audioNodes || [])
            nativeById[Number(node?.id)] = node;
        const targets = [];
        for (const nodeId of target.nodeIds) {
            const node = nativeById[nodeId];
            if (!node?.ready || !node?.audio)
                return applicationControlResult(false, "stream-changed", "An application stream changed before the control was applied.", request, 0);
            targets.push(node);
        }

        for (const node of targets) {
            if (Math.abs(Number(node.audio.volume) - volume) > 0.0001)
                node.audio.volume = volume;
            if (!!node.audio.muted !== muted)
                node.audio.muted = muted;
        }
        schedulePublish();
        return applicationControlResult(true, "accepted", "", request, targets.length);
    }

    function applyApplicationStreamState(request) {
        if (!ready)
            return applicationControlResult(false, "backend-unavailable", "PipeWire is not ready.", request, 0);
        const target = AudioApplicationControlModel.streamControlTarget(applications, request?.groupKey, request?.sessionId, request?.operation);
        if (!target.accepted)
            return applicationControlResult(false, target.code, target.message, request, 0);
        const continuity = AudioApplicationControlModel.targetContinuity(target.group, request);
        if (!continuity.accepted)
            return applicationControlResult(false, continuity.code, continuity.message, request, 0);

        const volume = Number(request?.volume);
        const muted = request?.muted;
        if (!Number.isFinite(volume) || typeof muted !== "boolean")
            return applicationControlResult(false, "invalid-state", "The requested stream sound state is invalid.", request, 0);

        const nodeId = Number(target.nodeIds[0]);
        const node = (audioNodes || []).find(candidate => Number(candidate?.id) === nodeId);
        if (!node?.ready || !node?.audio)
            return applicationControlResult(false, "stream-changed", "The audio stream changed before the control was applied.", request, 0);

        if (Math.abs(Number(node.audio.volume) - volume) > 0.0001)
            node.audio.volume = volume;
        if (!!node.audio.muted !== muted)
            node.audio.muted = muted;
        schedulePublish();
        return applicationControlResult(true, "accepted", "", request, 1);
    }

    function showTestDeviceTransition(role, kind) {
        return hotplugCoordinator.showTestTransition(role, kind);
    }

    function synchronizeNodes() {
        audioNodes = (Pipewire.nodes?.values || []).filter(node => !!node?.audio);
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

    function compactNode(node, normalizedRecords) {
        if (!node)
            return null;
        const nodeId = Number(node.id);
        const normalized = (normalizedRecords || []).find(record => Number(record?.id) === nodeId);
        return {
            id: nodeId,
            stableKey: String(normalized?.stableKey || ""),
            name: String(node.description || node.nickname || node.name || ""),
            ready: !!node.ready,
            role: String(normalized?.role || "")
        };
    }

    function linkRecords() {
        const result = [];
        for (const link of Pipewire.linkGroups?.values || []) {
            if (!link?.source?.audio || !link?.target?.audio)
                continue;
            result.push({
                sourceId: link.source.id,
                targetId: link.target.id
            });
        }
        result.sort((left, right) => left.sourceId - right.sourceId || left.targetId - right.targetId);
        return result;
    }

    function publish() {
        const normalized = AudioNodeModel.normalizedNodes(audioNodes.map(node => rawNode(node)));
        nodes = AudioNodeModel.reconciledNodes(retainedOrder, normalized);
        if (ready) {
            retainedOrder = nodes.map(record => ({
                        stableKey: record.stableKey
                    }));
        }
        links = linkRecords();
        applications = AudioApplicationModel.groupedApplications(nodes, links);
        roleCounts = AudioNodeModel.roleCounts(normalized);
        defaults = {
            output: compactNode(Pipewire.defaultAudioSink, normalized),
            input: compactNode(Pipewire.defaultAudioSource, normalized),
            preferredOutput: compactNode(Pipewire.preferredDefaultAudioSink, normalized),
            preferredInput: compactNode(Pipewire.preferredDefaultAudioSource, normalized)
        };
        revision += 1;
    }

    Component.onCompleted: {
        if (Pipewire.ready)
            synchronizeNodes();
        else
            schedulePublish();
    }

    Connections {
        target: Pipewire

        function onReadyChanged() {
            if (Pipewire.ready) {
                root.connectionTimedOut = false;
                root.synchronizeNodes();
            } else {
                root.audioNodes = [];
                connectionWatchdog.restart();
                root.schedulePublish();
            }
        }

        function onDefaultAudioSinkChanged() {
            root.schedulePublish();
        }

        function onDefaultAudioSourceChanged() {
            root.schedulePublish();
        }

        function onDefaultConfiguredAudioSinkChanged() {
            root.schedulePublish();
        }

        function onDefaultConfiguredAudioSourceChanged() {
            root.schedulePublish();
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
            root.schedulePublish();
        }
    }

    PwObjectTracker {
        objects: root.audioNodes
    }

    AudioDefaultCoordinator {
        id: defaultCoordinator

        backendReady: root.ready
        nativeNodes: root.audioNodes
        records: root.nodes
    }

    AudioHotplugCoordinator {
        id: hotplugCoordinator

        records: root.nodes
        defaults: root.defaults

        onTransitionOccurred: transition => root.deviceTransitionOccurred(transition)
    }

    AudioRouteProvider {
        id: routeProvider

        records: root.nodes
        applications: root.applications
        links: root.links
        defaultOutputId: Number(root.defaults?.output?.id) || 0
        graphRevision: root.revision
        commandExecutor: routeCommandRunner

        onResultOccurred: result => root.applicationRouteResultOccurred(result)
    }

    AudioRouteCommandRunner {
        id: routeCommandRunner
    }

    AudioRoutePolicyCoordinator {
        id: routePolicyCoordinator

        policies: root.routePolicies
        applications: root.applications
        targets: routeProvider.targets
        defaultOutputId: Number(root.defaults?.output?.id) || 0
        graphRevision: root.revision
        provider: routeProvider
    }

    Instantiator {
        model: root.audioNodes

        delegate: QtObject {
            id: watcher

            required property var modelData

            property Connections nodeChanges: Connections {
                target: watcher.modelData

                function onPropertiesChanged() {
                    root.schedulePublish();
                }

                function onReadyChanged() {
                    root.schedulePublish();
                }
            }

            property Connections audioChanges: Connections {
                target: watcher.modelData?.audio ?? null

                function onChannelsChanged() {
                    root.schedulePublish();
                }

                function onMutedChanged() {
                    root.schedulePublish();
                }

                function onVolumesChanged() {
                    root.schedulePublish();
                }
            }
        }
    }

    Timer {
        id: publishDebounce

        interval: 80
        onTriggered: root.publish()
    }

    Timer {
        id: connectionWatchdog

        interval: 3000
        running: !root.ready && !root.connectionTimedOut
        onTriggered: {
            if (!root.ready)
                root.connectionTimedOut = true;
        }
    }
}
