import QtQuick

QtObject {
    id: root

    required property var outputState
    required property var inputState
    required property var outputSelection
    required property var inputSelection
    required property var outputPending
    required property var inputPending
    required property var requestDevice
    required property var requestPreset
    required property var requestVolume
    property bool busy: false
    property var operation: null

    signal completed(int token, var result)
    signal failed(int token, string code, string message, var result)

    function stateForRole(role) {
        return role === "output" ? outputState : role === "input" ? inputState : null;
    }

    function selectionForRole(role) {
        return role === "output" ? outputSelection : role === "input" ? inputSelection : null;
    }

    function pendingForRole(role) {
        return role === "output" ? outputPending : role === "input" ? inputPending : null;
    }

    function acceptedResult(result) {
        return result?.accepted === true;
    }

    function run(step, token, rollingBack) {
        if (busy || !step || Number(token) <= 0)
            return false;
        const kind = String(step.kind || "");
        if (kind !== "device" && kind !== "preset" && kind !== "ceiling" && kind !== "volume")
            return false;
        busy = true;
        operation = {
            token: Number(token),
            kind: kind,
            role: String(step.role || ""),
            pipeline: String(step.pipeline || ""),
            stableKey: String(step.stableKey || ""),
            preset: String(step.preset || ""),
            value: Number(step.value),
            rollingBack: rollingBack === true,
            mutationAccepted: false,
            requestSequence: 0,
            rollbackStep: rollingBack === true ? null : step.rollback || null
        };
        if (kind === "device")
            startDevice();
        else if (kind === "preset")
            startPreset();
        else
            startVolume();
        return true;
    }

    function startDevice() {
        const result = requestDevice(operation.role, operation.stableKey);
        if (!acceptedResult(result)) {
            deferFailure(String(result?.code || "device-failed"), String(result?.message || "The audio device could not be selected."), false);
            return;
        }
        if (result.code === "unchanged") {
            deferCompletion(false, null);
            return;
        }
        operation = Object.assign({}, operation, {
            mutationAccepted: true,
            requestSequence: Number(result.sequence) || 0
        });
        operationTimeout.restart();
        reconcileDevice();
    }

    function startPreset() {
        const result = requestPreset(operation.pipeline, operation.preset);
        if (!acceptedResult(result)) {
            deferFailure(String(result?.code || "preset-failed"), String(result?.message || "The effects preset could not be loaded."), false);
            return;
        }
        operation = Object.assign({}, operation, {
            mutationAccepted: true,
            requestSequence: Number(result.sequence) || 0
        });
        operationTimeout.restart();
    }

    function startVolume() {
        const state = stateForRole(operation.role);
        const current = Number(state?.volume);
        const requested = Number(operation.value);
        if (state?.available !== true || !Number.isFinite(current) || !Number.isFinite(requested)) {
            deferFailure("volume-unavailable", "The " + operation.role + " level is unavailable.", false);
            return;
        }
        const target = operation.kind === "ceiling" ? Math.min(current, requested) : requested;
        if (Math.abs(current - target) <= 0.0001) {
            deferCompletion(false, null);
            return;
        }
        const rollbackStep = operation.rollingBack ? null : {
            kind: "volume",
            role: operation.role,
            value: current
        };
        operation = Object.assign({}, operation, {
            value: target,
            rollbackStep: rollbackStep
        });
        const result = requestVolume(operation.role, target);
        if (!acceptedResult(result)) {
            deferFailure(String(result?.code || "volume-failed"), String(result?.message || "The audio level could not be changed."), false);
            return;
        }
        if (result.code === "unchanged") {
            deferCompletion(false, null);
            return;
        }
        operation = Object.assign({}, operation, {
            mutationAccepted: true,
            requestSequence: Number(result.sequence) || 0
        });
        operationTimeout.restart();
        reconcileVolume();
    }

    function reconcileDevice() {
        if (!busy || operation?.kind !== "device")
            return;
        const selection = selectionForRole(operation.role);
        if (Number(selection?.sequence) !== Number(operation.requestSequence))
            return;
        if (selection?.phase === "confirmed" && String(selection?.requestedStableKey || "") === operation.stableKey) {
            finishCompleted(true, operation.rollbackStep);
            return;
        }
        if (selection?.phase === "failed" || selection?.phase === "superseded")
            finishFailed(String(selection?.code || "device-unconfirmed"), String(selection?.message || "The audio device change was not confirmed."), true);
    }

    function reconcileVolume() {
        if (!busy || operation?.kind !== "ceiling" && operation?.kind !== "volume")
            return;
        const pending = pendingForRole(operation.role);
        if (pending?.active === true)
            return;
        const state = stateForRole(operation.role);
        const observed = Number(state?.volume);
        if (state?.available === true && Number.isFinite(observed) && Math.abs(observed - operation.value) <= 0.002) {
            finishCompleted(true, operation.rollbackStep);
            return;
        }
        finishFailed("volume-unconfirmed", "The audio level change was not confirmed.", true);
    }

    function handleEffectsResult(result) {
        if (!busy || operation?.kind !== "preset")
            return;
        if (Number(result?.sequence) !== Number(operation.requestSequence))
            return;
        if (result?.accepted === true && result?.kind === "preset" && String(result?.pipeline || "") === operation.pipeline && String(result?.preset || "") === operation.preset)
            finishCompleted(true, operation.rollbackStep);
        else
            finishFailed(String(result?.code || "preset-unconfirmed"), String(result?.message || "The effects preset change was not confirmed."), true);
    }

    function deferCompletion(changed, rollbackStep) {
        const token = operation.token;
        Qt.callLater(() => {
            if (root.busy && root.operation?.token === token)
                root.finishCompleted(changed, rollbackStep);
        });
    }

    function deferFailure(code, message, rollbackRequired) {
        const token = operation.token;
        Qt.callLater(() => {
            if (root.busy && root.operation?.token === token)
                root.finishFailed(code, message, rollbackRequired);
        });
    }

    function finishCompleted(changed, rollbackStep) {
        const completedOperation = operation;
        operationTimeout.stop();
        busy = false;
        operation = null;
        completed(completedOperation.token, {
            changed: changed === true,
            rollbackStep: rollbackStep || null
        });
    }

    function finishFailed(code, message, rollbackRequired) {
        const failedOperation = operation;
        operationTimeout.stop();
        busy = false;
        operation = null;
        failed(failedOperation.token, code, message, {
            rollbackRequired: rollbackRequired === true && failedOperation.rollingBack !== true,
            rollbackStep: failedOperation.rollbackStep || null
        });
    }

    onOutputSelectionChanged: reconcileDevice()
    onInputSelectionChanged: reconcileDevice()
    onOutputStateChanged: reconcileVolume()
    onInputStateChanged: reconcileVolume()
    onOutputPendingChanged: reconcileVolume()
    onInputPendingChanged: reconcileVolume()

    property Timer operationTimeout: Timer {
        interval: 2200
        onTriggered: root.finishFailed("confirmation-timeout", "The audio scene step was not confirmed in time.", true)
    }
}
