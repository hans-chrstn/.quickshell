import QtQuick
import QtTest
import "../../services/audio"

TestCase {
    id: testCase

    name: "AudioControlCoordinator"

    function record(role, id, volume, muted) {
        return {
            role: role,
            available: true,
            id: id,
            key: role + ":device-" + id,
            name: "Device " + id,
            ready: true,
            volume: volume,
            muted: muted,
            capabilities: {
                volumeWrite: true,
                muteWrite: true
            }
        };
    }

    QtObject {
        id: provider

        property bool ready: true
        property int revision: 1
        property int applyCount: 0
        property var output: testCase.record("output", 10, 0.5, false)
        property var input: testCase.record("input", 20, 0.6, false)

        function applyState(role, volume, muted, operation) {
            applyCount += 1;
            if (role === "output")
                output = Object.assign({}, output, {
                    volume: volume,
                    muted: muted
                });
            else
                input = Object.assign({}, input, {
                    volume: volume,
                    muted: muted
                });
            revision += 1;
            return {
                accepted: true,
                code: "accepted",
                message: "",
                role: role,
                operation: operation,
                nodeId: role === "output" ? output.id : input.id,
                revision: revision
            };
        }

        function externalState(role, volume, muted) {
            if (role === "output")
                output = Object.assign({}, output, {
                    volume: volume,
                    muted: muted
                });
            else
                input = Object.assign({}, input, {
                    volume: volume,
                    muted: muted
                });
            revision += 1;
        }

        function replaceOutput(id) {
            output = testCase.record("output", id, 0.3, false);
            revision += 1;
        }
    }

    AudioControlCoordinator {
        id: coordinator

        provider: provider
        policy: ({
                step: 0.05,
                outputCeiling: 1,
                inputCeiling: 1,
                muteAtZero: true,
                restoreOnUnmute: true
            })
    }

    SignalSpy {
        id: changeSpy

        target: coordinator
        signalName: "semanticChange"
    }

    function init() {
        coordinator.flushTimer.stop();
        coordinator.confirmationTimer.stop();
        coordinator.outputPending = coordinator.emptyPending("output");
        coordinator.inputPending = coordinator.emptyPending("input");
        coordinator.outputBaseline = record("output", 10, 0.5, false);
        coordinator.inputBaseline = record("input", 20, 0.6, false);
        coordinator.outputInitialized = true;
        coordinator.inputInitialized = true;
        coordinator.outputLevelMemory = coordinator.emptyMemory();
        coordinator.inputLevelMemory = coordinator.emptyMemory();
        coordinator.sequence = 0;
        coordinator.lastChange = null;
        coordinator.lastResult = null;
        coordinator.requestCount = 0;
        coordinator.coalescedRequestCount = 0;
        coordinator.nativeApplyCount = 0;
        coordinator.confirmedCount = 0;
        coordinator.suppressedEchoCount = 0;
        coordinator.externalChangeCount = 0;
        coordinator.cancelledCount = 0;
        coordinator.timeoutCount = 0;
        provider.applyCount = 0;
        provider.output = record("output", 10, 0.5, false);
        provider.input = record("input", 20, 0.6, false);
        changeSpy.clear();
    }

    function test_startupBaselineEmitsNothing() {
        coordinator.outputInitialized = false;
        coordinator.inputInitialized = false;
        coordinator.reconcile();

        compare(changeSpy.count, 0);
        compare(coordinator.sequence, 0);
    }

    function test_rapidAdjustmentsCoalesceIntoOneNativeWrite() {
        coordinator.adjustVolume("output", 1);
        coordinator.adjustVolume("output", 1);
        coordinator.adjustVolume("output", 1);

        compare(coordinator.output.volume, 0.65);
        compare(coordinator.requestCount, 3);
        compare(coordinator.coalescedRequestCount, 2);
        compare(changeSpy.count, 3);
        coordinator.flushTimer.stop();
        coordinator.flush();

        compare(provider.applyCount, 1);
        compare(coordinator.nativeApplyCount, 1);
        compare(coordinator.confirmedCount, 1);
        compare(coordinator.suppressedEchoCount, 1);
        compare(changeSpy.count, 3);
        verify(!coordinator.outputPending.active);
    }

    function test_externalChangeEmitsOnce() {
        provider.externalState("input", 0.4, true);

        compare(changeSpy.count, 1);
        compare(coordinator.externalChangeCount, 1);
        compare(coordinator.lastChange.source, "external");
        compare(coordinator.lastChange.role, "input");
    }

    function test_deviceReplacementCancelsQueuedWriteWithoutHudEvent() {
        coordinator.adjustVolume("output", 1);
        compare(changeSpy.count, 1);
        provider.replaceOutput(11);

        compare(coordinator.cancelledCount, 1);
        verify(!coordinator.outputPending.active);
        compare(changeSpy.count, 1);
        compare(coordinator.output.id, 11);
        compare(coordinator.output.volume, 0.3);
        compare(coordinator.outputLevelMemory.key, "output:device-11");
        compare(coordinator.outputLevelMemory.value, 0.3);
        compare(provider.applyCount, 0);
    }
}
