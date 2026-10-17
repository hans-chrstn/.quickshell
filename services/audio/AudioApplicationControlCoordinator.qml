import QtQuick
import "AudioApplicationControlModel.js" as AudioApplicationControlModel
import "AudioControlPolicy.js" as AudioControlPolicy

QtObject {
    id: root

    required property var provider
    required property var policy
    property var pendingByGroup: ({})
    property int sequence: 0
    property int requestCount: 0
    property int coalescedRequestCount: 0
    property int nativeApplyCount: 0
    property int confirmedCount: 0
    property int cancelledCount: 0
    property int timeoutCount: 0
    property var lastResult: null
    readonly property bool busy: Object.keys(pendingByGroup).length > 0
    readonly property int revision: sequence

    function rejected(groupKey, operation, code, message, requestedValue) {
        const result = {
            accepted: false,
            code: code,
            message: message,
            groupKey: String(groupKey || ""),
            operation: String(operation || ""),
            requestedValue: requestedValue,
            sequence: sequence
        };
        lastResult = result;
        return result;
    }

    function pending(groupKey) {
        return pendingByGroup[String(groupKey || "")] || null;
    }

    function publishPending(groupKey, value) {
        const updated = Object.assign({}, pendingByGroup);
        if (value)
            updated[groupKey] = value;
        else
            delete updated[groupKey];
        pendingByGroup = updated;
        sequence += 1;
    }

    function effectiveGroup(group) {
        const queued = pending(group?.key);
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

    function plan(groupKey, operation, requestedValue) {
        if (!provider)
            return rejected(groupKey, operation, "inventory-unavailable", "Open the Apps page before changing application sound.", requestedValue);
        const target = AudioApplicationControlModel.controlTarget(provider.applications, groupKey, operation);
        if (!target.accepted)
            return rejected(groupKey, operation, target.code, target.message, requestedValue);

        const group = effectiveGroup(target.group);
        const controlPlan = operation === "volume" ? AudioControlPolicy.volumePlan(target.role, requestedValue, group.volume, policy) : AudioControlPolicy.mutePlan(target.role, group.volume, group.muted, requestedValue, group.volume, policy);
        if (!controlPlan.accepted)
            return rejected(groupKey, operation, controlPlan.code, controlPlan.message, requestedValue);
        return Object.assign({}, target, controlPlan, {
            active: true,
            phase: "queued",
            groupKey: target.groupKey,
            nodeIds: target.nodeIds,
            requestCount: Number(pending(groupKey)?.requestCount) + 1 || 1
        });
    }

    function queue(groupKey, operation, requestedValue) {
        const next = plan(groupKey, operation, requestedValue);
        if (!next.accepted)
            return next;
        const current = effectiveGroup(next.group);
        if (Math.abs(Number(current.volume) - Number(next.volume)) <= 0.0001 && current.muted === next.muted) {
            const unchanged = Object.assign({}, next, {
                code: "unchanged",
                phase: "confirmed",
                sequence: sequence
            });
            lastResult = unchanged;
            return unchanged;
        }

        const wasPending = pending(groupKey)?.active === true;
        requestCount += 1;
        if (wasPending)
            coalescedRequestCount += 1;
        publishPending(next.groupKey, next);
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
        return queue(groupKey, "volume", value);
    }

    function setMuted(groupKey, muted) {
        return queue(groupKey, "mute", muted);
    }

    function adjustVolume(groupKey, steps) {
        const count = Number(steps);
        if (!Number.isFinite(count) || count === 0)
            return rejected(groupKey, "volume", "invalid-adjustment", "Adjustment steps must be a non-zero finite number.", steps);
        const group = AudioApplicationControlModel.groupByKey(provider?.applications, groupKey);
        if (!group)
            return rejected(groupKey, "volume", "application-ended", "The application is no longer producing an audio stream.", steps);
        const effective = effectiveGroup(group);
        return setVolume(groupKey, Number(effective.volume) + count * Number(policy.step));
    }

    function cancel(groupKey, code, message) {
        const queued = pending(groupKey);
        if (!queued)
            return;
        cancelledCount += 1;
        publishPending(groupKey, null);
        lastResult = rejected(groupKey, queued.operation, code, message, {
            volume: queued.volume,
            muted: queued.muted
        });
    }

    function flush() {
        for (const groupKey of Object.keys(pendingByGroup)) {
            const queued = pending(groupKey);
            if (queued?.phase !== "queued")
                continue;
            publishPending(groupKey, Object.assign({}, queued, {
                phase: "awaiting"
            }));
            const result = provider?.applyApplicationState ? provider.applyApplicationState(queued) : ({
                    accepted: false,
                    code: "inventory-unavailable",
                    message: "The application inventory is unavailable."
                });
            if (!result.accepted) {
                cancel(groupKey, result.code, result.message);
                continue;
            }
            nativeApplyCount += 1;
        }
        if (busy)
            confirmationTimer.restart();
    }

    function reconcile() {
        for (const groupKey of Object.keys(pendingByGroup)) {
            const queued = pending(groupKey);
            if (queued?.phase !== "awaiting")
                continue;
            const group = AudioApplicationControlModel.groupByKey(provider?.applications, groupKey);
            if (!group) {
                cancel(groupKey, "application-ended", "The application ended before PipeWire confirmed the change.");
                continue;
            }
            if (AudioApplicationControlModel.targetMatches(group, queued, 0.02)) {
                confirmedCount += 1;
                publishPending(groupKey, null);
            }
        }
        if (!busy)
            confirmationTimer.stop();
    }

    function expirePending() {
        const keys = Object.keys(pendingByGroup);
        timeoutCount += keys.length;
        for (const groupKey of keys)
            cancel(groupKey, "confirmation-timeout", "PipeWire did not confirm the application sound change in time.");
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
            pending: pendingByGroup,
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
