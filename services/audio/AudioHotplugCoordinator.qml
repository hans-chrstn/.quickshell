import QtQuick
import "AudioHotplugModel.js" as AudioHotplugModel

QtObject {
    id: root

    required property var records
    required property var defaults
    property var outputState: AudioHotplugModel.emptyState("output")
    property var inputState: AudioHotplugModel.emptyState("input")
    readonly property var outputTransition: outputState.event
    readonly property var inputTransition: inputState.event

    signal transitionOccurred(var transition)

    function scheduleReconcile() {
        reconcileTimer.restart();
    }

    function currentDefault(role) {
        return role === "input" ? defaults?.input ?? null : defaults?.output ?? null;
    }

    function reconcileRole(role) {
        const previous = role === "input" ? inputState : outputState;
        const next = AudioHotplugModel.reconcile(previous, records, currentDefault(role));
        if (role === "input")
            inputState = next;
        else
            outputState = next;
        if (next.event.sequence <= previous.event.sequence)
            return;
        transitionOccurred(next.event);
    }

    function reconcileAll() {
        reconcileRole("output");
        reconcileRole("input");
    }

    function showTestTransition(role, kind) {
        if (role !== "output" && role !== "input")
            return false;
        const allowedKinds = ["fallback", "disconnected", "restored", "available-again"];
        if (!allowedKinds.includes(kind))
            return false;
        const previous = role === "input" ? inputState : outputState;
        const sequence = previous.sequence + 1;
        const fromName = role === "input" ? "Studio microphone" : "Studio output";
        const target = currentDefault(role);
        const toName = String(target?.name || (role === "input" ? "Built-in microphone" : "Built-in audio"));
        const transition = {
            kind: kind,
            role: role,
            fromStableKey: role + "-device:test-studio",
            fromName: fromName,
            toStableKey: String(target?.stableKey || role + "-device:test-fallback"),
            toName: toName,
            message: AudioHotplugModel.messageFor(kind, role, fromName, toName),
            sequence: sequence
        };
        const next = Object.assign({}, previous, {
            sequence: sequence,
            event: transition
        });
        if (role === "input") {
            inputState = next;
        } else {
            outputState = next;
        }
        transitionOccurred(transition);
        return true;
    }

    Component.onCompleted: scheduleReconcile()
    onRecordsChanged: scheduleReconcile()
    onDefaultsChanged: scheduleReconcile()

    property Timer reconcileTimer: Timer {
        interval: 0
        onTriggered: root.reconcileAll()
    }
}
