import QtQuick
import QtTest
import "../../services/audio"

TestCase {
    id: testCase

    name: "AudioSceneOperationExecutor"

    property var outputState: state("output", 0.8)
    property var inputState: state("input", 0.6)
    property var outputSelection: selection("output")
    property var inputSelection: selection("input")
    property var outputPending: pending("output", false)
    property var inputPending: pending("input", false)
    property int requestSequence: 0
    property var requests: []

    function state(role, volume) {
        return {
            role: role,
            available: true,
            volume: volume
        };
    }

    function selection(role) {
        return {
            role: role,
            phase: "idle",
            requestedStableKey: "",
            sequence: 0
        };
    }

    function pending(role, active) {
        return {
            role: role,
            active: active
        };
    }

    function requestDevice(role, stableKey) {
        requestSequence += 1;
        requests = requests.concat([
            {
                kind: "device",
                role: role,
                stableKey: stableKey
            }
        ]);
        return {
            accepted: true,
            code: "requested",
            sequence: requestSequence
        };
    }

    function requestPreset(pipeline, preset) {
        requestSequence += 1;
        requests = requests.concat([
            {
                kind: "preset",
                pipeline: pipeline,
                preset: preset
            }
        ]);
        return {
            accepted: true,
            code: "accepted",
            sequence: requestSequence
        };
    }

    function requestVolume(role, value) {
        requestSequence += 1;
        requests = requests.concat([
            {
                kind: "volume",
                role: role,
                value: value
            }
        ]);
        if (role === "output")
            outputPending = pending("output", true);
        else
            inputPending = pending("input", true);
        return {
            accepted: true,
            code: "queued",
            sequence: requestSequence
        };
    }

    AudioSceneOperationExecutor {
        id: executor

        outputState: testCase.outputState
        inputState: testCase.inputState
        outputSelection: testCase.outputSelection
        inputSelection: testCase.inputSelection
        outputPending: testCase.outputPending
        inputPending: testCase.inputPending
        requestDevice: testCase.requestDevice
        requestPreset: testCase.requestPreset
        requestVolume: testCase.requestVolume
    }

    SignalSpy {
        id: completedSpy

        target: executor
        signalName: "completed"
    }

    SignalSpy {
        id: failedSpy

        target: executor
        signalName: "failed"
    }

    function init() {
        executor.operationTimeout.stop();
        executor.busy = false;
        executor.operation = null;
        outputState = state("output", 0.8);
        inputState = state("input", 0.6);
        outputSelection = selection("output");
        inputSelection = selection("input");
        outputPending = pending("output", false);
        inputPending = pending("input", false);
        requestSequence = 0;
        requests = [];
        completedSpy.clear();
        failedSpy.clear();
    }

    function test_deviceWaitsForMatchingAuthoritativeConfirmation() {
        const step = {
            kind: "device",
            role: "output",
            stableKey: "output-device:headphones",
            rollback: {
                kind: "device",
                role: "output",
                stableKey: "output-device:speakers"
            }
        };
        verify(executor.run(step, 4, false));
        verify(executor.busy);
        outputSelection = {
            role: "output",
            phase: "confirmed",
            requestedStableKey: step.stableKey,
            sequence: requestSequence + 1
        };
        compare(completedSpy.count, 0);
        outputSelection = {
            role: "output",
            phase: "confirmed",
            requestedStableKey: step.stableKey,
            sequence: requestSequence
        };
        compare(completedSpy.count, 1);
        compare(completedSpy.signalArguments[0][1].rollbackStep.stableKey, "output-device:speakers");
    }

    function test_ceilingCapturesRuntimeVolumeAndWaitsForPendingConfirmation() {
        verify(executor.run({
            kind: "ceiling",
            role: "output",
            value: 0.3
        }, 5, false));
        compare(requests[0].value, 0.3);
        outputState = state("output", 0.3);
        compare(completedSpy.count, 0);
        outputPending = pending("output", false);
        compare(completedSpy.count, 1);
        compare(completedSpy.signalArguments[0][1].rollbackStep.value, 0.8);
    }

    function test_ceilingNeverRaisesAndCompletesAsUnchanged() {
        outputState = state("output", 0.2);
        verify(executor.run({
            kind: "ceiling",
            role: "output",
            value: 0.5
        }, 6, false));
        tryCompare(completedSpy, "count", 1);
        compare(requests.length, 0);
        verify(!completedSpy.signalArguments[0][1].changed);
    }

    function test_presetRequiresMatchingProviderResult() {
        verify(executor.run({
            kind: "preset",
            pipeline: "input",
            preset: "Voice",
            rollback: {
                kind: "preset",
                pipeline: "input",
                preset: "Default"
            }
        }, 7, false));
        executor.handleEffectsResult({
            accepted: true,
            sequence: requestSequence + 1,
            kind: "preset",
            pipeline: "input",
            preset: "Voice"
        });
        compare(completedSpy.count, 0);
        executor.handleEffectsResult({
            accepted: true,
            sequence: requestSequence,
            kind: "preset",
            pipeline: "input",
            preset: "Voice"
        });
        compare(completedSpy.count, 1);
    }

    function test_failedDeviceConfirmationRequiresRollback() {
        verify(executor.run({
            kind: "device",
            role: "input",
            stableKey: "input-device:microphone",
            rollback: {
                kind: "device",
                role: "input",
                stableKey: "input-device:previous"
            }
        }, 8, false));
        inputSelection = {
            role: "input",
            phase: "failed",
            requestedStableKey: "input-device:microphone",
            code: "device-unavailable",
            message: "gone",
            sequence: requestSequence
        };
        compare(failedSpy.count, 1);
        verify(failedSpy.signalArguments[0][3].rollbackRequired);
    }
}
