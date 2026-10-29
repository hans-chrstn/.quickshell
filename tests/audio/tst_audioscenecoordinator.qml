import QtQuick
import QtTest
import "../../services/audio"

TestCase {
    id: testCase

    name: "AudioSceneCoordinator"

    QtObject {
        id: executor

        property bool acceptsRuns: true
        property var calls: []

        signal completed(int token, var result)
        signal failed(int token, string code, string message, var result)

        function run(step, token, rollingBack) {
            if (!acceptsRuns)
                return false;
            calls = calls.concat([
                {
                    step: step,
                    token: token,
                    rollingBack: rollingBack
                }
            ]);
            return true;
        }

        function succeed(result) {
            completed(calls[calls.length - 1].token, result || ({}));
        }

        function reject(code, rollbackRequired, rollbackStep) {
            failed(calls[calls.length - 1].token, code || "failed", "failed", {
                rollbackRequired: rollbackRequired === true,
                rollbackStep: rollbackStep || null
            });
        }
    }

    AudioSceneCoordinator {
        id: coordinator

        executor: executor
    }

    SignalSpy {
        id: resultSpy

        target: coordinator
        signalName: "resultOccurred"
    }

    function step(kind, id) {
        return {
            kind: kind,
            role: "output",
            stableKey: id,
            rollback: {
                kind: kind,
                role: "output",
                stableKey: "previous-" + id
            }
        };
    }

    function init() {
        coordinator.stepTimeout.stop();
        coordinator.busy = false;
        coordinator.sequence = 0;
        coordinator.operation = null;
        coordinator.lastResult = null;
        coordinator.requestCount = 0;
        coordinator.confirmedCount = 0;
        coordinator.rollbackCount = 0;
        coordinator.failedCount = 0;
        coordinator.timeoutCount = 0;
        executor.acceptsRuns = true;
        executor.calls = [];
        resultSpy.clear();
    }

    function test_successSerializesAndConfirmsEveryStep() {
        const result = coordinator.request("studio", [step("device", "speakers"), step("preset", "music")]);
        verify(result.accepted);
        compare(executor.calls.length, 1);
        executor.succeed({
            changed: true
        });
        compare(executor.calls.length, 2);
        executor.succeed({
            changed: true
        });

        verify(!coordinator.busy);
        compare(coordinator.lastResult.code, "confirmed");
        compare(coordinator.lastResult.appliedStepCount, 2);
        compare(coordinator.confirmedCount, 1);
        compare(resultSpy.count, 1);
    }

    function test_failureRollsBackCompletedStepsInReverseOrder() {
        coordinator.request("studio", [step("device", "speakers"), step("preset", "music"), step("device", "microphone")]);
        executor.succeed({
            changed: true
        });
        executor.succeed({
            changed: true
        });
        executor.reject("third-failed", false, null);

        compare(executor.calls.length, 4);
        verify(executor.calls[3].rollingBack);
        compare(executor.calls[3].step.stableKey, "previous-music");
        executor.succeed({
            changed: true
        });
        compare(executor.calls[4].step.stableKey, "previous-speakers");
        executor.succeed({
            changed: true
        });

        verify(!coordinator.busy);
        compare(coordinator.lastResult.code, "third-failed");
        verify(coordinator.lastResult.rollbackConfirmed);
        compare(coordinator.rollbackCount, 1);
    }

    function test_failedMutatingStepParticipatesInRollback() {
        const rollback = {
            kind: "volume",
            role: "output",
            value: 0.8
        };
        coordinator.request("night", [
            {
                kind: "ceiling",
                role: "output",
                value: 0.3
            }
        ]);
        executor.reject("mismatch", true, rollback);

        compare(executor.calls.length, 2);
        verify(executor.calls[1].rollingBack);
        compare(executor.calls[1].step, rollback);
        executor.succeed({
            changed: true
        });
        compare(coordinator.lastResult.code, "mismatch");
        verify(coordinator.lastResult.rollbackConfirmed);
    }

    function test_unchangedCompletesWithoutExecutorOrRollback() {
        const result = coordinator.request("studio", []);
        verify(result.accepted);
        compare(result.code, "unchanged");
        compare(result.appliedStepCount, 0);
        compare(executor.calls.length, 0);
        compare(resultSpy.count, 1);
        verify(!coordinator.busy);
    }

    function test_runtimeNoOpStepsReportTruthfulUnchangedResult() {
        coordinator.request("studio", [step("device", "speakers")]);
        executor.succeed({
            changed: false
        });
        compare(coordinator.lastResult.code, "unchanged");
        compare(coordinator.lastResult.appliedStepCount, 0);
        compare(coordinator.confirmedCount, 0);
    }

    function test_staleCompletionAndUnavailableExecutorFailClosed() {
        coordinator.request("studio", [step("device", "speakers")]);
        executor.completed(99, {
            changed: true
        });
        verify(coordinator.busy);
        executor.succeed({
            changed: true
        });
        verify(!coordinator.busy);

        executor.acceptsRuns = false;
        const rejected = coordinator.request("other", [step("device", "headphones")]);
        verify(!rejected.accepted);
        compare(coordinator.lastResult.code, "executor-unavailable");
    }
}
