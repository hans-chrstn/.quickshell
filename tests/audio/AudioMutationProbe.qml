import QtQuick
import Quickshell.Services.Pipewire
import "AudioNodeModel.js" as AudioNodeModel

QtObject {
    id: root

    required property var nodes
    property var targetNode: null
    property var originalDefaultNode: null
    property var state: idleState()
    property var evidence: ({
            volume: false,
            mute: false,
            outputDefault: false,
            inputDefault: false
        })

    readonly property bool active: state.active

    signal statePublished

    function idleState() {
        return {
            active: false,
            operation: "none",
            phase: "idle",
            nodeId: -1,
            role: "",
            originalValue: null,
            requestedValue: null,
            targetObserved: null,
            restoredObserved: null,
            effectiveTargetObserved: null,
            effectiveRestoredObserved: null,
            success: null,
            error: ""
        };
    }

    function publish(changes) {
        const next = Object.assign({}, state);
        for (const key in changes)
            next[key] = changes[key];
        state = next;
        statePublished();
    }

    function response(accepted, error) {
        return {
            accepted: accepted,
            error: error || "",
            probe: snapshot()
        };
    }

    function snapshot() {
        return Object.assign({}, state, {
            evidence: Object.assign({}, evidence)
        });
    }

    function nodeById(nodeId) {
        const numericId = Number(nodeId);
        for (const node of nodes || []) {
            if (Number(node?.id) === numericId)
                return node;
        }
        return null;
    }

    function validateNode(nodeId) {
        if (active)
            return "Another mutation probe is already active.";
        if (!Pipewire.ready)
            return "PipeWire is not ready.";
        const node = nodeById(nodeId);
        if (!node)
            return "The requested node is no longer available.";
        if (!node.audio || !node.ready)
            return "The requested node is not a ready audio node.";
        return "";
    }

    function begin(operation, node, originalValue, requestedValue, role) {
        targetNode = node;
        publish({
            active: true,
            operation: operation,
            phase: "awaiting-target",
            nodeId: Number(node.id),
            role: role || "",
            originalValue: originalValue,
            requestedValue: requestedValue,
            targetObserved: null,
            restoredObserved: null,
            effectiveTargetObserved: null,
            effectiveRestoredObserved: null,
            success: null,
            error: ""
        });
        settleTimer.restart();
    }

    function probeVolume(nodeId) {
        const error = validateNode(nodeId);
        if (error.length > 0)
            return response(false, error);
        const node = nodeById(nodeId);
        const original = Number(node.audio.volume);
        const requested = AudioNodeModel.safeProbeVolume(original);
        begin("volume", node, original, requested, "");
        node.audio.volume = requested;
        return response(true, "");
    }

    function probeMute(nodeId) {
        const error = validateNode(nodeId);
        if (error.length > 0)
            return response(false, error);
        const node = nodeById(nodeId);
        const original = !!node.audio.muted;
        begin("mute", node, original, !original, "");
        node.audio.muted = !original;
        return response(true, "");
    }

    function probeDefault(role, nodeId) {
        const error = validateNode(nodeId);
        if (error.length > 0)
            return response(false, error);
        if (role !== "output" && role !== "input")
            return response(false, "Role must be output or input.");

        const node = nodeById(nodeId);
        if (node.isStream)
            return response(false, "Application streams cannot become device defaults.");
        if ((role === "output") !== !!node.isSink)
            return response(false, "The requested node does not match the default role.");

        originalDefaultNode = role === "output" ? Pipewire.preferredDefaultAudioSink : Pipewire.preferredDefaultAudioSource;
        begin("default", node, originalDefaultNode?.id ?? -1, Number(node.id), role);
        if (role === "output")
            Pipewire.preferredDefaultAudioSink = node;
        else
            Pipewire.preferredDefaultAudioSource = node;
        return response(true, "");
    }

    function currentDefault(role, preferred) {
        if (role === "output")
            return preferred ? Pipewire.preferredDefaultAudioSink : Pipewire.defaultAudioSink;
        return preferred ? Pipewire.preferredDefaultAudioSource : Pipewire.defaultAudioSource;
    }

    function observeTarget() {
        if (!targetNode) {
            finish(false, "The target node disappeared before confirmation.");
            return;
        }

        let observed = false;
        let effective = null;
        if (state.operation === "volume")
            observed = AudioNodeModel.approximatelyEqual(targetNode.audio.volume, state.requestedValue, 0.02);
        else if (state.operation === "mute")
            observed = targetNode.audio.muted === state.requestedValue;
        else {
            observed = currentDefault(state.role, true) === targetNode;
            effective = currentDefault(state.role, false) === targetNode;
        }

        publish({
            phase: "awaiting-restore",
            targetObserved: observed,
            effectiveTargetObserved: effective
        });
        restoreOriginal();
        settleTimer.restart();
    }

    function restoreOriginal() {
        if (state.operation === "volume" && targetNode?.audio)
            targetNode.audio.volume = state.originalValue;
        else if (state.operation === "mute" && targetNode?.audio)
            targetNode.audio.muted = state.originalValue;
        else if (state.operation === "default") {
            if (state.role === "output")
                Pipewire.preferredDefaultAudioSink = originalDefaultNode;
            else
                Pipewire.preferredDefaultAudioSource = originalDefaultNode;
        }
    }

    function observeRestore() {
        let restored = false;
        let effective = null;
        if (state.operation === "volume" && targetNode?.audio)
            restored = AudioNodeModel.approximatelyEqual(targetNode.audio.volume, state.originalValue, 0.02);
        else if (state.operation === "mute" && targetNode?.audio)
            restored = targetNode.audio.muted === state.originalValue;
        else if (state.operation === "default") {
            restored = currentDefault(state.role, true) === originalDefaultNode;
            effective = currentDefault(state.role, false) === originalDefaultNode;
        }

        const targetConfirmed = state.targetObserved === true;
        const effectiveTargetConfirmed = state.operation !== "default" || state.effectiveTargetObserved === true;
        const effectiveRestoreConfirmed = state.operation !== "default" || effective === true;
        finish(targetConfirmed && restored && effectiveTargetConfirmed && effectiveRestoreConfirmed, "", restored, effective);
    }

    function finish(success, error, restored, effectiveRestored) {
        settleTimer.stop();
        if (success) {
            const updatedEvidence = Object.assign({}, evidence);
            if (state.operation === "volume")
                updatedEvidence.volume = true;
            else if (state.operation === "mute")
                updatedEvidence.mute = true;
            else if (state.operation === "default" && state.role === "output")
                updatedEvidence.outputDefault = true;
            else if (state.operation === "default" && state.role === "input")
                updatedEvidence.inputDefault = true;
            evidence = updatedEvidence;
        }
        publish({
            active: false,
            phase: success ? "complete" : "failed",
            restoredObserved: restored ?? false,
            effectiveRestoredObserved: effectiveRestored ?? null,
            success: success,
            error: error || ""
        });
        targetNode = null;
        originalDefaultNode = null;
    }

    function restoreNow() {
        if (!active)
            return response(false, "No mutation probe is active.");
        settleTimer.stop();
        publish({
            phase: "awaiting-restore"
        });
        restoreOriginal();
        settleTimer.restart();
        return response(true, "");
    }

    function handleNodesChanged() {
        if (!active || nodeById(state.nodeId))
            return;
        if (state.operation === "default")
            restoreOriginal();
        finish(false, "The target node disappeared during the mutation probe.");
    }

    Component.onDestruction: {
        if (active)
            restoreOriginal();
    }

    property Timer settleTimer: Timer {
        interval: 900
        onTriggered: {
            if (root.state.phase === "awaiting-target")
                root.observeTarget();
            else if (root.state.phase === "awaiting-restore")
                root.observeRestore();
        }
    }
}
