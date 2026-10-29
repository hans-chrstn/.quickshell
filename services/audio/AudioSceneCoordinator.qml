import QtQuick

QtObject {
    id: root

    required property var executor
    property bool busy: false
    property int sequence: 0
    property var operation: null
    property var lastResult: null
    property int requestCount: 0
    property int confirmedCount: 0
    property int rollbackCount: 0
    property int failedCount: 0
    property int timeoutCount: 0

    signal resultOccurred(var result)

    function response(accepted, code, message, extra) {
        return Object.assign({
            accepted: accepted,
            code: code,
            message: message || "",
            sceneId: String(operation?.sceneId || extra?.sceneId || ""),
            sequence: sequence
        }, extra || ({}));
    }

    function request(sceneId, steps) {
        if (busy)
            return response(false, "busy", "Another audio scene change is still active.", {
                sceneId: String(sceneId || "")
            });
        const actions = Array.isArray(steps) ? steps.slice() : [];
        sequence += 1;
        requestCount += 1;
        if (actions.length === 0) {
            const unchanged = response(true, "unchanged", "", {
                sceneId: String(sceneId || ""),
                appliedStepCount: 0,
                rollbackConfirmed: false
            });
            lastResult = unchanged;
            resultOccurred(unchanged);
            return unchanged;
        }
        operation = {
            token: sequence,
            sceneId: String(sceneId || ""),
            phase: "applying",
            steps: actions,
            stepIndex: 0,
            appliedStepCount: 0,
            rollbackSteps: [],
            rollbackIndex: -1,
            failureCode: "",
            failureMessage: ""
        };
        busy = true;
        if (!startCurrentStep()) {
            finish(false, "executor-unavailable", "The audio scene executor is unavailable.", false);
            return response(false, "executor-unavailable", "The audio scene executor is unavailable.");
        }
        return response(true, "accepted", "", {
            sceneId: operation.sceneId,
            appliedStepCount: 0,
            rollbackConfirmed: false
        });
    }

    function publishOperation(changes) {
        operation = Object.assign({}, operation || ({}), changes);
    }

    function startCurrentStep() {
        const step = operation?.steps?.[operation.stepIndex];
        if (!step)
            return false;
        stepTimeout.restart();
        return executor?.run(step, operation.token, false) === true;
    }

    function startCurrentRollback() {
        const step = operation?.rollbackSteps?.[operation.rollbackIndex];
        if (!step)
            return false;
        stepTimeout.restart();
        return executor?.run(step, operation.token, true) === true;
    }

    function addRollback(step, result) {
        if (result?.changed === false)
            return;
        const rollbackStep = result?.rollbackStep || step?.rollback || null;
        if (rollbackStep)
            publishOperation({
                rollbackSteps: operation.rollbackSteps.concat([rollbackStep])
            });
    }

    function handleCompleted(token, result) {
        if (!busy || token !== operation?.token)
            return;
        stepTimeout.stop();
        if (operation.phase === "applying") {
            const step = operation.steps[operation.stepIndex];
            addRollback(step, result);
            if (result?.changed === true)
                publishOperation({
                    appliedStepCount: operation.appliedStepCount + 1
                });
            const nextIndex = operation.stepIndex + 1;
            if (nextIndex >= operation.steps.length) {
                const changed = operation.appliedStepCount > 0;
                if (changed)
                    confirmedCount += 1;
                finish(true, changed ? "confirmed" : "unchanged", "", false);
                return;
            }
            publishOperation({
                stepIndex: nextIndex
            });
            if (!startCurrentStep())
                startRollback("executor-unavailable", "The audio scene executor became unavailable.");
            return;
        }
        if (operation.phase === "rolling-back") {
            const nextIndex = operation.rollbackIndex - 1;
            if (nextIndex < 0) {
                finish(false, operation.failureCode, operation.failureMessage, true);
                return;
            }
            publishOperation({
                rollbackIndex: nextIndex
            });
            if (!startCurrentRollback())
                finish(false, "rollback-failed", "The audio scene rollback executor became unavailable.", false);
        }
    }

    function handleFailed(token, code, message, result) {
        if (!busy || token !== operation?.token)
            return;
        stepTimeout.stop();
        if (operation.phase === "rolling-back") {
            finish(false, "rollback-failed", message || "The audio scene rollback could not be confirmed.", false);
            return;
        }
        const step = operation.steps[operation.stepIndex];
        if (result?.rollbackRequired === true)
            addRollback(step, result);
        startRollback(code || "step-failed", message || "An audio scene step failed.");
    }

    function startRollback(code, message) {
        const rollbackSteps = operation?.rollbackSteps || [];
        if (rollbackSteps.length === 0) {
            finish(false, code, message, true);
            return;
        }
        rollbackCount += 1;
        publishOperation({
            phase: "rolling-back",
            rollbackIndex: rollbackSteps.length - 1,
            failureCode: code,
            failureMessage: message
        });
        if (!startCurrentRollback())
            finish(false, "rollback-failed", "The audio scene rollback executor is unavailable.", false);
    }

    function finish(accepted, code, message, rollbackConfirmed) {
        stepTimeout.stop();
        const completed = operation;
        const result = response(accepted, code, message, {
            sceneId: String(completed?.sceneId || ""),
            appliedStepCount: Number(completed?.appliedStepCount) || 0,
            rollbackConfirmed: rollbackConfirmed === true
        });
        if (!accepted)
            failedCount += 1;
        busy = false;
        operation = null;
        lastResult = result;
        resultOccurred(result);
        return result;
    }

    function diagnostics() {
        return {
            busy: busy,
            sequence: sequence,
            operation: operation,
            lastResult: lastResult,
            requestCount: requestCount,
            confirmedCount: confirmedCount,
            rollbackCount: rollbackCount,
            failedCount: failedCount,
            timeoutCount: timeoutCount,
            stepTimeoutMs: stepTimeout.interval
        };
    }

    property Connections executorConnections: Connections {
        target: root.executor
        ignoreUnknownSignals: true

        function onCompleted(token, result) {
            root.handleCompleted(token, result);
        }

        function onFailed(token, code, message, result) {
            root.handleFailed(token, code, message, result);
        }
    }

    property Timer stepTimeout: Timer {
        interval: 3000
        onTriggered: {
            root.timeoutCount += 1;
            if (root.operation?.phase === "rolling-back")
                root.finish(false, "rollback-timeout", "The audio scene rollback was not confirmed in time.", false);
            else
                root.startRollback("confirmation-timeout", "The audio scene change was not confirmed in time.");
        }
    }
}
