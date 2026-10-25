import QtQuick
import "AudioRouteModel.js" as AudioRouteModel

Item {
    id: root

    required property var records
    required property var applications
    required property var links
    required property int defaultOutputId
    required property int graphRevision
    property bool busy: false
    property int sequence: 0
    property var operation: null
    property var lastResult: null
    required property var commandExecutor
    property int requestCount: 0
    property int commandCount: 0
    property int confirmedCount: 0
    property int rollbackCount: 0
    property int failedCount: 0
    property int timeoutCount: 0
    property var abortReason: null
    readonly property var targets: AudioRouteModel.outputTargets(records)
    signal resultOccurred(var result)

    visible: false
    width: 0
    height: 0

    function normalizedOrigin(value) {
        const origin = String(value || "manual");
        return origin === "policy-apply" || origin === "policy-fallback" ? origin : "manual";
    }

    function response(accepted, code, message, plan, origin) {
        return {
            accepted: accepted,
            code: code,
            message: message || "",
            groupKey: String(plan?.groupKey || ""),
            applicationKey: String(plan?.applicationKey || ""),
            targetStableKey: String(plan?.targetStableKey || ""),
            followDefault: !!plan?.followDefault,
            origin: normalizedOrigin(origin),
            sequence: sequence
        };
    }

    function request(groupKey, targetStableKey, origin) {
        const requestOrigin = normalizedOrigin(origin);
        if (busy)
            return response(false, "busy", "Another application route change is still active.", null, requestOrigin);
        const plan = AudioRouteModel.applicationRoutePlan(applications, records, groupKey, targetStableKey, defaultOutputId);
        if (!plan.accepted)
            return response(false, plan.code, plan.message, plan, requestOrigin);

        sequence += 1;
        requestCount += 1;
        abortReason = null;
        operation = {
            token: sequence,
            origin: requestOrigin,
            phase: "reading-originals",
            plan: plan,
            originals: ({}),
            metadataConfirmed: false,
            linksConfirmed: false,
            rollbackConfirmed: false,
            failureCode: "",
            failureMessage: ""
        };
        busy = true;
        if (!runCommands(AudioRouteModel.queryCommands(plan.streamIds))) {
            finish(false, "runner-unavailable", "The audio route command runner is unavailable.", false);
            return response(false, "runner-unavailable", "The audio route command runner is unavailable.", plan, requestOrigin);
        }
        return response(true, "accepted", "", plan, requestOrigin);
    }

    function runCommands(commands) {
        if (!commandExecutor?.run(commands, operation?.token || 0))
            return false;
        commandCount += commands.length;
        return true;
    }

    function metadataByStream(results) {
        const snapshots = ({});
        for (const result of results || [])
            snapshots[String(result.streamId)] = AudioRouteModel.metadataState(result.stdout);
        return snapshots;
    }

    function everyStreamHasSnapshot(snapshots) {
        return (operation?.plan?.streamIds || []).every(streamId => snapshots?.[String(streamId)] !== undefined);
    }

    function everyMetadataMatchesPlan(snapshots) {
        return (operation?.plan?.streamIds || []).every(streamId => AudioRouteModel.metadataMatches(snapshots?.[String(streamId)], operation.plan));
    }

    function everyMetadataRestored(snapshots) {
        return (operation?.plan?.streamIds || []).every(streamId => AudioRouteModel.metadataEqual(snapshots?.[String(streamId)], operation?.originals?.[String(streamId)]));
    }

    function publishOperation(changes) {
        operation = Object.assign({}, operation || ({}), changes);
    }

    function startMutation() {
        const continuity = AudioRouteModel.routeContinuity(operation?.plan, applications, records, defaultOutputId);
        if (!continuity.accepted) {
            finish(false, continuity.code, continuity.message, false);
            return;
        }
        publishOperation({
            phase: "mutating"
        });
        if (!runCommands(AudioRouteModel.mutationCommands(operation.plan)))
            finish(false, "runner-unavailable", "The audio route command runner is unavailable.", false);
    }

    function startVerification() {
        publishOperation({
            phase: "verifying-metadata"
        });
        if (!runCommands(AudioRouteModel.queryCommands(operation.plan.streamIds)))
            startRollback("runner-unavailable", "The audio route command runner became unavailable during verification.");
    }

    function startRollback(code, message) {
        confirmationTimer.stop();
        rollbackCount += 1;
        abortReason = null;
        publishOperation({
            phase: "rolling-back",
            failureCode: code,
            failureMessage: message
        });
        if (!runCommands(AudioRouteModel.rollbackCommands(operation.plan.streamIds, operation.originals)))
            finish(false, "rollback-failed", "The audio route command runner was unavailable during rollback.", false);
    }

    function startRollbackVerification() {
        publishOperation({
            phase: "verifying-rollback"
        });
        if (!runCommands(AudioRouteModel.queryCommands(operation.plan.streamIds)))
            finish(false, "rollback-unconfirmed", "The restored application route metadata could not be verified.", false);
    }

    function reconcile() {
        if (!busy || !operation)
            return;
        const phase = String(operation.phase || "");
        const continuity = AudioRouteModel.routeContinuity(operation.plan, applications, records, defaultOutputId);
        if (!continuity.accepted && phase !== "rolling-back" && phase !== "verifying-rollback") {
            if (commandExecutor?.busy) {
                abortReason = {
                    code: continuity.code,
                    message: continuity.message
                };
            } else if (Object.keys(operation.originals || ({})).length > 0) {
                startRollback(continuity.code, continuity.message);
            } else {
                finish(false, continuity.code, continuity.message, false);
            }
            return;
        }
        if (phase === "awaiting-links" && AudioRouteModel.routesMatch(operation.plan, records, links, defaultOutputId)) {
            confirmationTimer.stop();
            confirmedCount += 1;
            publishOperation({
                linksConfirmed: true
            });
            finish(true, "confirmed", "", false);
        }
    }

    function handleCompleted(token, results) {
        if (!busy || token !== operation?.token)
            return;
        const phase = String(operation.phase || "");
        if (phase === "reading-originals") {
            const originals = metadataByStream(results);
            if (!everyStreamHasSnapshot(originals)) {
                finish(false, "metadata-incomplete", "The original application route metadata could not be captured.", false);
                return;
            }
            publishOperation({
                originals: originals
            });
            if (abortReason) {
                finish(false, abortReason.code, abortReason.message, false);
                return;
            }
            startMutation();
        } else if (phase === "mutating") {
            if (abortReason) {
                startRollback(abortReason.code, abortReason.message);
                return;
            }
            startVerification();
        } else if (phase === "verifying-metadata") {
            const observed = metadataByStream(results);
            if (!everyStreamHasSnapshot(observed) || !everyMetadataMatchesPlan(observed)) {
                startRollback("metadata-unconfirmed", "PipeWire did not confirm the requested route metadata.");
                return;
            }
            if (abortReason) {
                startRollback(abortReason.code, abortReason.message);
                return;
            }
            publishOperation({
                phase: "awaiting-links",
                metadataConfirmed: true
            });
            confirmationTimer.restart();
            reconcile();
        } else if (phase === "rolling-back") {
            startRollbackVerification();
        } else if (phase === "verifying-rollback") {
            const restored = metadataByStream(results);
            if (!everyStreamHasSnapshot(restored) || !everyMetadataRestored(restored)) {
                finish(false, "rollback-unconfirmed", "The prior application route metadata could not be confirmed after rollback.", false);
                return;
            }
            finish(false, operation.failureCode || "route-failed", operation.failureMessage || "The route change failed and was rolled back.", true);
        }
    }

    function handleCommandFailure(token, code, message) {
        if (!busy || token !== operation?.token)
            return;
        const phase = String(operation.phase || "");
        if (code === "command-timeout")
            timeoutCount += 1;
        if (phase === "reading-originals") {
            finish(false, code, message, false);
        } else if (phase === "rolling-back" || phase === "verifying-rollback") {
            finish(false, "rollback-failed", message, false);
        } else {
            startRollback(code, message);
        }
    }

    function finish(success, code, message, rollbackConfirmed) {
        confirmationTimer.stop();
        if (!success)
            failedCount += 1;
        const result = response(success, code, message, operation?.plan, operation?.origin);
        result.metadataConfirmed = !!operation?.metadataConfirmed;
        result.linksConfirmed = !!operation?.linksConfirmed;
        result.rollbackConfirmed = !!rollbackConfirmed;
        lastResult = result;
        resultOccurred(result);
        operation = null;
        abortReason = null;
        busy = false;
    }

    function diagnostics() {
        return {
            busy: busy,
            sequence: sequence,
            requestCount: requestCount,
            commandCount: commandCount,
            confirmedCount: confirmedCount,
            rollbackCount: rollbackCount,
            failedCount: failedCount,
            timeoutCount: timeoutCount,
            phase: String(operation?.phase || "idle"),
            pendingGroupKey: String(operation?.plan?.groupKey || ""),
            pendingTargetStableKey: String(operation?.plan?.targetStableKey || ""),
            pendingOrigin: String(operation?.origin || ""),
            followDefault: !!operation?.plan?.followDefault,
            metadataConfirmed: !!operation?.metadataConfirmed,
            linksConfirmed: !!operation?.linksConfirmed,
            lastResult: lastResult,
            targets: targets
        };
    }

    onGraphRevisionChanged: reconcile()

    property Timer confirmationTimer: Timer {
        id: confirmationTimer

        interval: 900
        onTriggered: {
            root.timeoutCount += 1;
            root.startRollback("confirmation-timeout", "PipeWire did not confirm the requested application route in time.");
        }
    }

    Connections {
        target: root.commandExecutor
        ignoreUnknownSignals: true

        function onCompleted(token, results) {
            root.handleCompleted(token, results);
        }

        function onFailed(token, commandIndex, code, message, results) {
            root.handleCommandFailure(token, code, message);
        }
    }
}
