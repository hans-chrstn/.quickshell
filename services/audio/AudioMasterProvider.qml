import QtQuick
import Quickshell.Services.Pipewire

QtObject {
    id: root

    readonly property bool ready: Pipewire.ready
    readonly property var outputNode: Pipewire.defaultAudioSink
    readonly property var inputNode: Pipewire.defaultAudioSource
    readonly property var trackedNodes: {
        const result = [];
        if (outputNode)
            result.push(outputNode);
        if (inputNode && inputNode !== outputNode)
            result.push(inputNode);
        return result;
    }
    property var output: unavailableRecord("output")
    property var input: unavailableRecord("input")
    property int revision: 0

    function unavailableRecord(role) {
        return {
            role: role,
            available: false,
            id: -1,
            name: "",
            ready: false,
            volume: null,
            muted: null,
            capabilities: {
                volumeRead: false,
                volumeWrite: false,
                muteRead: false,
                muteWrite: false
            }
        };
    }

    function recordFor(role, node) {
        const available = !!node;
        const nodeReady = available && !!node.ready && !!node.audio;
        return {
            role: role,
            available: available,
            id: available ? Number(node.id) : -1,
            key: available ? role + ":" + String(node.name || "") : "",
            name: available ? String(node.description || node.nickname || node.name || "") : "",
            ready: nodeReady,
            volume: nodeReady ? Number(node.audio.volume) : null,
            muted: nodeReady ? !!node.audio.muted : null,
            capabilities: {
                volumeRead: nodeReady,
                volumeWrite: nodeReady,
                muteRead: nodeReady,
                muteWrite: nodeReady
            }
        };
    }

    function publish() {
        output = recordFor("output", outputNode);
        input = recordFor("input", inputNode);
        revision += 1;
    }

    function schedulePublish() {
        publishDebounce.restart();
    }

    function nodeForRole(role) {
        return role === "output" ? outputNode : role === "input" ? inputNode : null;
    }

    function rejected(role, operation, code, message, requestedValue) {
        return {
            accepted: false,
            code: code,
            message: message,
            role: role,
            operation: operation,
            requestedValue: requestedValue,
            nodeId: -1,
            revision: revision
        };
    }

    function accepted(role, operation, requestedValue, node) {
        return {
            accepted: true,
            code: "accepted",
            message: "",
            role: role,
            operation: operation,
            requestedValue: requestedValue,
            nodeId: Number(node.id),
            revision: revision
        };
    }

    function applyState(role, volume, muted, operation) {
        if (!ready)
            return rejected(role, operation, "backend-unavailable", "PipeWire is not ready.", {
                volume: volume,
                muted: muted
            });
        const node = nodeForRole(role);
        if (!node)
            return rejected(role, operation, "default-unavailable", "The default " + role + " device is unavailable.", {
                volume: volume,
                muted: muted
            });
        if (!node.ready || !node.audio)
            return rejected(role, operation, "control-unavailable", "The default " + role + " device is not ready for control.", {
                volume: volume,
                muted: muted
            });
        if (!Number.isFinite(Number(volume)) || typeof muted !== "boolean")
            return rejected(role, operation, "invalid-state", "The requested audio state is invalid.", {
                volume: volume,
                muted: muted
            });
        if (Math.abs(Number(node.audio.volume) - Number(volume)) > 0.0001)
            node.audio.volume = volume;
        if (!!node.audio.muted !== muted)
            node.audio.muted = muted;
        schedulePublish();
        return accepted(role, operation, {
            volume: volume,
            muted: muted
        }, node);
    }

    Component.onCompleted: schedulePublish()

    property Connections pipewireChanges: Connections {
        target: Pipewire

        function onReadyChanged() {
            root.schedulePublish();
        }

        function onDefaultAudioSinkChanged() {
            root.schedulePublish();
        }

        function onDefaultAudioSourceChanged() {
            root.schedulePublish();
        }
    }

    property Connections outputNodeChanges: Connections {
        target: root.outputNode
        ignoreUnknownSignals: true

        function onReadyChanged() {
            root.schedulePublish();
        }
    }

    property Connections outputAudioChanges: Connections {
        target: root.outputNode?.audio ?? null

        function onMutedChanged() {
            root.schedulePublish();
        }

        function onVolumesChanged() {
            root.schedulePublish();
        }
    }

    property Connections inputNodeChanges: Connections {
        target: root.inputNode
        ignoreUnknownSignals: true

        function onReadyChanged() {
            root.schedulePublish();
        }
    }

    property Connections inputAudioChanges: Connections {
        target: root.inputNode?.audio ?? null

        function onMutedChanged() {
            root.schedulePublish();
        }

        function onVolumesChanged() {
            root.schedulePublish();
        }
    }

    property PwObjectTracker tracker: PwObjectTracker {
        objects: root.trackedNodes
    }

    property Timer publishDebounce: Timer {
        interval: 30
        onTriggered: root.publish()
    }
}
