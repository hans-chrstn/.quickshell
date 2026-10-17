import QtQuick
import Quickshell.Services.Pipewire
import "AudioDefaultModel.js" as AudioDefaultModel

QtObject {
    id: root

    required property bool backendReady
    required property var nativeNodes
    required property var records
    property int sequence: 0
    property var outputState: AudioDefaultModel.emptyState("output", records)
    property var inputState: AudioDefaultModel.emptyState("input", records)

    function stateForRole(role) {
        return role === "output" ? outputState : role === "input" ? inputState : null;
    }

    function setState(role, state) {
        if (role === "output")
            outputState = state;
        else if (role === "input")
            inputState = state;
    }

    function nativeNodeById(nodeId) {
        const requestedId = Number(nodeId);
        for (const node of nativeNodes || []) {
            if (Number(node?.id) === requestedId)
                return node;
        }
        return null;
    }

    function rejected(role, stableKey, plan) {
        const normalizedRole = AudioDefaultModel.normalizedRole(role);
        sequence += 1;
        const state = Object.assign({}, AudioDefaultModel.emptyState(normalizedRole, records), {
            phase: "failed",
            requestedStableKey: String(stableKey || ""),
            code: plan.code,
            message: plan.message,
            sequence: sequence
        });
        if (normalizedRole.length > 0)
            setState(normalizedRole, state);
        return {
            accepted: false,
            code: plan.code,
            message: plan.message,
            role: normalizedRole,
            stableKey: String(stableKey || ""),
            sequence: sequence
        };
    }

    function request(role, stableKey) {
        const plan = AudioDefaultModel.requestPlan(role, stableKey, records, backendReady);
        if (!plan.accepted)
            return rejected(role, stableKey, plan);

        sequence += 1;
        const state = AudioDefaultModel.requestedState(plan.role, plan.target, sequence, records);
        setState(plan.role, state);
        if (plan.code === "unchanged") {
            stopTimeout(plan.role);
            return {
                accepted: true,
                code: "unchanged",
                message: "",
                role: plan.role,
                stableKey: plan.target.stableKey,
                nodeId: plan.target.id,
                sequence: sequence
            };
        }

        const nativeNode = nativeNodeById(plan.target.id);
        if (!nativeNode)
            return rejected(plan.role, stableKey, {
                code: "native-device-unavailable",
                message: "The native PipeWire device disappeared before the request could be applied."
            });

        if (plan.role === "output")
            Pipewire.preferredDefaultAudioSink = nativeNode;
        else
            Pipewire.preferredDefaultAudioSource = nativeNode;
        startTimeout(plan.role);
        Qt.callLater(root.reconcileRole, plan.role);
        return {
            accepted: true,
            code: "requested",
            message: "",
            role: plan.role,
            stableKey: plan.target.stableKey,
            nodeId: plan.target.id,
            sequence: sequence
        };
    }

    function reconcileRole(role) {
        const state = stateForRole(role);
        if (!state)
            return;
        const reconciled = AudioDefaultModel.reconciledState(state, records);
        setState(role, reconciled);
        if (reconciled.phase === "confirmed" || reconciled.phase === "failed" || reconciled.phase === "superseded")
            stopTimeout(role);
    }

    function reconcileAll() {
        reconcileRole("output");
        reconcileRole("input");
    }

    function startTimeout(role) {
        if (role === "output")
            outputTimeout.restart();
        else
            inputTimeout.restart();
    }

    function stopTimeout(role) {
        if (role === "output")
            outputTimeout.stop();
        else
            inputTimeout.stop();
    }

    onRecordsChanged: reconcileAll()
    onBackendReadyChanged: reconcileAll()

    property Connections pipewireChanges: Connections {
        target: Pipewire

        function onDefaultAudioSinkChanged() {
            Qt.callLater(root.reconcileRole, "output");
        }

        function onDefaultAudioSourceChanged() {
            Qt.callLater(root.reconcileRole, "input");
        }

        function onDefaultConfiguredAudioSinkChanged() {
            Qt.callLater(root.reconcileRole, "output");
        }

        function onDefaultConfiguredAudioSourceChanged() {
            Qt.callLater(root.reconcileRole, "input");
        }
    }

    property Timer outputTimeout: Timer {
        interval: 1800
        onTriggered: root.outputState = AudioDefaultModel.timedOutState(root.outputState, root.records)
    }

    property Timer inputTimeout: Timer {
        interval: 1800
        onTriggered: root.inputState = AudioDefaultModel.timedOutState(root.inputState, root.records)
    }
}
