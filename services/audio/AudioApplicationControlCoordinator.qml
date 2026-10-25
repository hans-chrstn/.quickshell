import QtQuick
import "AudioApplicationControlModel.js" as AudioApplicationControlModel
import "AudioControlPolicy.js" as AudioControlPolicy

QtObject {
    id: root

    required property var provider
    required property var policy
    property var pendingByTarget: ({})
    property int sequence: 0
    property int requestCount: 0
    property int coalescedRequestCount: 0
    property int nativeApplyCount: 0
    property int confirmedCount: 0
    property int cancelledCount: 0
    property int timeoutCount: 0
    property var lastResult: null
    readonly property bool busy: Object.keys(pendingByTarget).length > 0
    readonly property int revision: sequence

    function targetKey(groupKey, sessionId) {
        const group = String(groupKey || "");
        const stream = String(sessionId || "");
        return JSON.stringify(stream.length > 0 ? ["stream", group, stream] : ["group", group]);
    }

    function rejected(groupKey, operation, code, message, requestedValue, sessionId) {
        const result = {
            accepted: false,
            code: code,
            message: message,
            groupKey: String(groupKey || ""),
            sessionId: String(sessionId || ""),
            operation: String(operation || ""),
            requestedValue: requestedValue,
            sequence: sequence
        };
        lastResult = result;
        return result;
    }

    function pending(key) {
        return pendingByTarget[String(key || "")] || null;
    }

    function publishPending(key, value) {
        const updated = Object.assign({}, pendingByTarget);
        if (value)
            updated[key] = value;
        else
            delete updated[key];
        pendingByTarget = updated;
        sequence += 1;
    }

    function effectiveGroup(group) {
        const queued = pending(targetKey(group?.key, ""));
        if (!queued?.active)
            return group;
        return Object.assign({}, group, {
            volume: queued.volume,
            muted: queued.muted,
            mixedVolume: false,
            mixedMute: false,
            controlPending: true
        });
    }

    function effectiveStream(groupKey, stream) {
        const queued = pending(targetKey(groupKey, stream?.sessionId));
        if (!queued?.active)
            return stream;
        return Object.assign({}, stream, {
            volume: queued.volume,
            muted: queued.muted,
            controlPending: true
        });
    }

    function plannedTarget(target, scope, requestedValue) {
        if (!target.accepted)
            return rejected(target.groupKey, target.operation, target.code, target.message, requestedValue, target.sessionId);
        const state = scope === "stream" ? effectiveStream(target.groupKey, target.stream) : effectiveGroup(target.group);
        const controlPlan = target.operation === "volume" ? AudioControlPolicy.volumePlan(target.role, requestedValue, state.volume, policy) : AudioControlPolicy.mutePlan(target.role, state.volume, state.muted, requestedValue, state.volume, policy);
        if (!controlPlan.accepted)
            return rejected(target.groupKey, target.operation, controlPlan.code, controlPlan.message, requestedValue, target.sessionId);
        const key = targetKey(target.groupKey, scope === "stream" ? target.sessionId : "");
        return Object.assign({}, target, controlPlan, {
            active: true,
            phase: "queued",
            scope: scope,
            targetKey: key,
            requestCount: Number(pending(key)?.requestCount) + 1 || 1
        });
    }

    function planGroup(groupKey, operation, requestedValue) {
        if (!provider)
            return rejected(groupKey, operation, "inventory-unavailable", "Open the Apps page before changing application sound.", requestedValue, "");
        return plannedTarget(AudioApplicationControlModel.controlTarget(provider.applications, groupKey, operation), "group", requestedValue);
    }

    function planStream(groupKey, sessionId, operation, requestedValue) {
        if (!provider)
            return rejected(groupKey, operation, "inventory-unavailable", "Open the application details before changing a stream.", requestedValue, sessionId);
        return plannedTarget(AudioApplicationControlModel.streamControlTarget(provider.applications, groupKey, sessionId, operation), "stream", requestedValue);
    }

    function cancelConflicts(next) {
        for (const key of Object.keys(pendingByTarget)) {
            const queued = pending(key);
            if (!queued || queued.targetKey === next.targetKey || queued.groupKey !== next.groupKey)
                continue;
            if (queued.scope === "group" || next.scope === "group")
                cancelTarget(key, "superseded", "A newer application sound change replaced this request.");
        }
    }

    function queue(next) {
        if (!next.accepted)
            return next;
        const current = next.scope === "stream" ? effectiveStream(next.groupKey, next.stream) : effectiveGroup(next.group);
        if (Math.abs(Number(current.volume) - Number(next.volume)) <= 0.0001 && current.muted === next.muted) {
            const unchanged = Object.assign({}, next, {
                code: "unchanged",
                phase: "confirmed",
                sequence: sequence
            });
            lastResult = unchanged;
            return unchanged;
        }

        cancelConflicts(next);
        const wasPending = pending(next.targetKey)?.active === true;
        requestCount += 1;
        if (wasPending)
            coalescedRequestCount += 1;
        publishPending(next.targetKey, next);
        if (!flushTimer.running)
            flushTimer.start();

        const result = Object.assign({}, next, {
            code: "queued",
            coalesced: wasPending,
            sequence: sequence
        });
        lastResult = result;
        return result;
    }

    function setVolume(groupKey, value) {
        return queue(planGroup(groupKey, "volume", value));
    }

    function setMuted(groupKey, muted) {
        return queue(planGroup(groupKey, "mute", muted));
    }

    function setStreamVolume(groupKey, sessionId, value) {
        return queue(planStream(groupKey, sessionId, "volume", value));
    }

    function setStreamMuted(groupKey, sessionId, muted) {
        return queue(planStream(groupKey, sessionId, "mute", muted));
    }

    function adjustVolume(groupKey, steps) {
        const count = Number(steps);
        if (!Number.isFinite(count) || count === 0)
            return rejected(groupKey, "volume", "invalid-adjustment", "Adjustment steps must be a non-zero finite number.", steps, "");
        const group = AudioApplicationControlModel.groupByKey(provider?.applications, groupKey);
        if (!group)
            return rejected(groupKey, "volume", "application-ended", "The application is no longer producing an audio stream.", steps, "");
        const effective = effectiveGroup(group);
        return setVolume(groupKey, Number(effective.volume) + count * Number(policy.step));
    }

    function adjustStreamVolume(groupKey, sessionId, steps) {
        const count = Number(steps);
        if (!Number.isFinite(count) || count === 0)
            return rejected(groupKey, "volume", "invalid-adjustment", "Adjustment steps must be a non-zero finite number.", steps, sessionId);
        const group = AudioApplicationControlModel.groupByKey(provider?.applications, groupKey);
        const stream = AudioApplicationControlModel.streamBySessionId(group, sessionId);
        if (!stream)
            return rejected(groupKey, "volume", "stream-ended", "The selected audio stream is no longer available.", steps, sessionId);
        const effective = effectiveStream(groupKey, stream);
        return setStreamVolume(groupKey, sessionId, Number(effective.volume) + count * Number(policy.step));
    }

    function cancelTarget(key, code, message) {
        const queued = pending(key);
        if (!queued)
            return;
        cancelledCount += 1;
        publishPending(key, null);
        lastResult = rejected(queued.groupKey, queued.operation, code, message, {
            volume: queued.volume,
            muted: queued.muted
        }, queued.sessionId);
    }

    function flush() {
        for (const key of Object.keys(pendingByTarget)) {
            const queued = pending(key);
            if (queued?.phase !== "queued")
                continue;
            publishPending(key, Object.assign({}, queued, {
                phase: "awaiting"
            }));
            const apply = queued.scope === "stream" ? provider?.applyApplicationStreamState : provider?.applyApplicationState;
            const result = apply ? apply.call(provider, queued) : ({
                    accepted: false,
                    code: "inventory-unavailable",
                    message: "The application inventory is unavailable."
                });
            if (!result.accepted) {
                cancelTarget(key, result.code, result.message);
                continue;
            }
            nativeApplyCount += 1;
        }
        if (busy)
            confirmationTimer.restart();
    }

    function reconcile() {
        for (const key of Object.keys(pendingByTarget)) {
            const queued = pending(key);
            if (queued?.phase !== "awaiting")
                continue;
            const group = AudioApplicationControlModel.groupByKey(provider?.applications, queued.groupKey);
            if (!group) {
                cancelTarget(key, "application-ended", "The application ended before PipeWire confirmed the change.");
                continue;
            }
            const continuity = AudioApplicationControlModel.targetContinuity(group, queued);
            if (!continuity.accepted) {
                cancelTarget(key, continuity.code, continuity.message);
                continue;
            }
            const matches = queued.scope === "stream" ? AudioApplicationControlModel.streamTargetMatches(group, queued, 0.02) : AudioApplicationControlModel.targetMatches(group, queued, 0.02);
            if (matches) {
                confirmedCount += 1;
                publishPending(key, null);
            }
        }
        if (!busy)
            confirmationTimer.stop();
    }

    function expirePending() {
        const keys = Object.keys(pendingByTarget);
        timeoutCount += keys.length;
        for (const key of keys)
            cancelTarget(key, "confirmation-timeout", "PipeWire did not confirm the application sound change in time.");
    }

    function diagnostics() {
        return {
            busy: busy,
            revision: revision,
            requestCount: requestCount,
            coalescedRequestCount: coalescedRequestCount,
            nativeApplyCount: nativeApplyCount,
            confirmedCount: confirmedCount,
            cancelledCount: cancelledCount,
            timeoutCount: timeoutCount,
            pending: pendingByTarget,
            lastResult: lastResult
        };
    }

    property Connections providerChanges: Connections {
        target: root.provider
        ignoreUnknownSignals: true

        function onRevisionChanged() {
            root.reconcile();
        }
    }

    property Timer flushTimer: Timer {
        interval: 16
        onTriggered: root.flush()
    }

    property Timer confirmationTimer: Timer {
        interval: 600
        onTriggered: root.expirePending()
    }
}
