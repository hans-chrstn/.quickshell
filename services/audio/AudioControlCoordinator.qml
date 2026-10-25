import QtQuick
import "AudioChangeModel.js" as AudioChangeModel
import "AudioControlPolicy.js" as AudioControlPolicy

QtObject {
    id: root

    required property var provider
    required property var policy

    property var outputPending: emptyPending("output")
    property var inputPending: emptyPending("input")
    property var outputBaseline: AudioChangeModel.normalizedRecord("output", null)
    property var inputBaseline: AudioChangeModel.normalizedRecord("input", null)
    property bool outputInitialized: false
    property bool inputInitialized: false
    property var outputLevelMemory: emptyMemory()
    property var inputLevelMemory: emptyMemory()

    readonly property var output: AudioChangeModel.effectiveRecord("output", provider.output, outputPending)
    readonly property var input: AudioChangeModel.effectiveRecord("input", provider.input, inputPending)
    property int sequence: 0
    property var lastChange: null
    property var lastResult: null
    property int requestCount: 0
    property int coalescedRequestCount: 0
    property int nativeApplyCount: 0
    property int confirmedCount: 0
    property int suppressedEchoCount: 0
    property int externalChangeCount: 0
    property int cancelledCount: 0
    property int timeoutCount: 0

    signal semanticChange(var change)

    function emptyMemory() {
        return {
            key: "",
            value: 0
        };
    }

    function emptyPending(role) {
        return {
            active: false,
            phase: "idle",
            role: role,
            key: "",
            id: -1,
            volume: null,
            muted: null,
            operation: "",
            requestCount: 0
        };
    }

    function nativeRecord(role) {
        return AudioChangeModel.normalizedRecord(role, role === "output" ? provider.output : provider.input);
    }

    function effectiveRecord(role) {
        return role === "output" ? output : role === "input" ? input : null;
    }

    function pendingForRole(role) {
        return role === "output" ? outputPending : inputPending;
    }

    function setPending(role, pending) {
        if (role === "output")
            outputPending = pending;
        else
            inputPending = pending;
    }

    function baselineForRole(role) {
        return role === "output" ? outputBaseline : inputBaseline;
    }

    function setBaseline(role, record) {
        if (role === "output") {
            outputBaseline = record;
            outputInitialized = true;
        } else {
            inputBaseline = record;
            inputInitialized = true;
        }
    }

    function initializedForRole(role) {
        return role === "output" ? outputInitialized : inputInitialized;
    }

    function memoryForRole(role, record) {
        const memory = role === "output" ? outputLevelMemory : inputLevelMemory;
        return memory.key === String(record?.key || "") ? Number(memory.value) || 0 : 0;
    }

    function rememberLevel(role, record, volume) {
        const numeric = Number(volume);
        const key = String(record?.key || "");
        if (key.length === 0 || !Number.isFinite(numeric) || numeric <= 0)
            return;
        const memory = {
            key: key,
            value: numeric
        };
        if (role === "output")
            outputLevelMemory = memory;
        else
            inputLevelMemory = memory;
    }

    function rejected(role, operation, code, message, requestedValue) {
        const result = {
            accepted: false,
            code: code,
            message: message,
            role: role,
            operation: operation,
            requestedValue: requestedValue,
            nodeId: -1,
            revision: provider.revision
        };
        lastResult = result;
        return result;
    }

    function validateRecord(role, operation, requestedValue) {
        const record = nativeRecord(role);
        if (!provider.ready)
            return rejected(role, operation, "backend-unavailable", "PipeWire is not ready.", requestedValue);
        if (!record.available)
            return rejected(role, operation, "default-unavailable", "The default " + role + " device is unavailable.", requestedValue);
        if (!record.ready || record.capabilities?.volumeWrite !== true || record.capabilities?.muteWrite !== true)
            return rejected(role, operation, "control-unavailable", "The default " + role + " device is not ready for control.", requestedValue);
        return null;
    }

    function publishLocalChange(operation, previous, current) {
        sequence += 1;
        const change = AudioChangeModel.semanticEvent(sequence, "local", operation, previous, current);
        lastChange = change;
        semanticChange(change);
    }

    function publishExternalChange(previous, current) {
        const fields = AudioChangeModel.changedFields(previous, current);
        if (fields.length === 0)
            return;
        sequence += 1;
        externalChangeCount += 1;
        const operation = fields.length === 1 ? fields[0] : "state";
        const change = AudioChangeModel.semanticEvent(sequence, "external", operation, previous, current);
        lastChange = change;
        semanticChange(change);
    }

    function queuePlan(plan, requestedValue) {
        const role = String(plan.role || "");
        const unavailable = validateRecord(role, plan.operation, requestedValue);
        if (unavailable)
            return unavailable;

        const previous = effectiveRecord(role);
        const native = nativeRecord(role);
        const target = Object.assign({}, native, {
            active: true,
            phase: "queued",
            volume: plan.volume,
            muted: plan.muted,
            operation: plan.operation,
            requestCount: Number(pendingForRole(role)?.requestCount) + 1 || 1
        });
        if (AudioChangeModel.sameState(previous, target)) {
            const unchanged = {
                accepted: true,
                code: "unchanged",
                message: "",
                role: role,
                operation: plan.operation,
                requestedValue: requestedValue,
                value: plan.volume,
                muted: plan.muted,
                clamped: plan.clamped,
                nodeId: native.id,
                revision: provider.revision
            };
            lastResult = unchanged;
            return unchanged;
        }

        const wasPending = pendingForRole(role)?.active === true;
        requestCount += 1;
        if (wasPending)
            coalescedRequestCount += 1;
        setPending(role, target);
        rememberLevel(role, native, plan.rememberedVolume);
        publishLocalChange(plan.operation, previous, target);
        if (!flushTimer.running)
            flushTimer.start();

        const result = {
            accepted: true,
            code: "queued",
            message: "",
            role: role,
            operation: plan.operation,
            requestedValue: requestedValue,
            value: plan.volume,
            muted: plan.muted,
            clamped: plan.clamped,
            coalesced: wasPending,
            nodeId: native.id,
            revision: provider.revision,
            sequence: sequence
        };
        lastResult = result;
        return result;
    }

    function setVolume(role, value) {
        const normalized = AudioControlPolicy.normalizedRole(role);
        const record = effectiveRecord(normalized);
        const plan = AudioControlPolicy.volumePlan(normalized, value, memoryForRole(normalized, record), policy);
        if (!plan.accepted)
            return rejected(normalized, "validation", plan.code, plan.message, value);
        return queuePlan(plan, value);
    }

    function setMuted(role, muted) {
        const normalized = AudioControlPolicy.normalizedRole(role);
        const record = effectiveRecord(normalized);
        const plan = AudioControlPolicy.mutePlan(normalized, record?.volume, record?.muted, muted, memoryForRole(normalized, record), policy);
        if (!plan.accepted)
            return rejected(normalized, "validation", plan.code, plan.message, muted);
        return queuePlan(plan, muted);
    }

    function adjustVolume(role, steps) {
        const normalized = AudioControlPolicy.normalizedRole(role);
        const record = effectiveRecord(normalized);
        const plan = AudioControlPolicy.adjustmentPlan(normalized, record?.volume, record?.muted, steps, memoryForRole(normalized, record), policy);
        if (!plan.accepted)
            return rejected(normalized, "validation", plan.code, plan.message, steps);
        return queuePlan(plan, steps);
    }

    function cancelPending(role, code, message) {
        const pending = pendingForRole(role);
        if (pending?.active !== true)
            return;
        cancelledCount += 1;
        setPending(role, emptyPending(role));
        lastResult = {
            accepted: false,
            code: code,
            message: message,
            role: role,
            operation: pending.operation,
            requestedValue: {
                volume: pending.volume,
                muted: pending.muted
            },
            nodeId: Number(pending.id),
            revision: provider.revision
        };
    }

    function flushRole(role) {
        const pending = pendingForRole(role);
        if (pending?.active !== true || pending.phase !== "queued")
            return;
        const current = nativeRecord(role);
        if (!AudioChangeModel.sameDevice(current, pending) || !current.ready) {
            cancelPending(role, "device-changed", "The default " + role + " device changed before the pending control was applied.");
            setBaseline(role, current);
            return;
        }
        setPending(role, Object.assign({}, pending, {
            phase: "awaiting"
        }));
        const result = provider.applyState(role, pending.volume, pending.muted, pending.operation);
        if (!result.accepted) {
            cancelPending(role, result.code, result.message);
            return;
        }
        nativeApplyCount += 1;
    }

    function flush() {
        flushRole("output");
        flushRole("input");
        if (outputPending.active || inputPending.active)
            confirmationTimer.restart();
    }

    function reconcileRole(role) {
        const current = nativeRecord(role);
        if (!initializedForRole(role)) {
            setBaseline(role, current);
            rememberLevel(role, current, current.volume);
            return;
        }

        const previous = baselineForRole(role);
        const pending = pendingForRole(role);
        if (!AudioChangeModel.sameDevice(previous, current)) {
            cancelPending(role, "device-changed", "The default " + role + " device changed while a control was pending.");
            setBaseline(role, current);
            rememberLevel(role, current, current.volume);
            return;
        }

        if (pending?.active === true) {
            if (AudioChangeModel.targetMatches(current, pending)) {
                confirmedCount += 1;
                suppressedEchoCount += 1;
                setPending(role, emptyPending(role));
                setBaseline(role, current);
                rememberLevel(role, current, current.volume);
            }
            return;
        }

        if (!AudioChangeModel.sameState(previous, current))
            publishExternalChange(previous, current);
        setBaseline(role, current);
        rememberLevel(role, current, current.volume);
    }

    function reconcile() {
        reconcileRole("output");
        reconcileRole("input");
        if (!outputPending.active && !inputPending.active)
            confirmationTimer.stop();
    }

    function expirePending() {
        const roles = ["output", "input"];
        for (const role of roles) {
            if (pendingForRole(role)?.active !== true)
                continue;
            timeoutCount += 1;
            cancelPending(role, "confirmation-timeout", "PipeWire did not confirm the pending " + role + " state in time.");
            setBaseline(role, nativeRecord(role));
        }
    }

    function diagnostics() {
        return {
            sequence: sequence,
            lastChange: lastChange,
            lastResult: lastResult,
            requestCount: requestCount,
            coalescedRequestCount: coalescedRequestCount,
            nativeApplyCount: nativeApplyCount,
            confirmedCount: confirmedCount,
            suppressedEchoCount: suppressedEchoCount,
            externalChangeCount: externalChangeCount,
            cancelledCount: cancelledCount,
            timeoutCount: timeoutCount,
            flushIntervalMs: flushTimer.interval,
            confirmationTimeoutMs: confirmationTimer.interval,
            pending: {
                output: outputPending,
                input: inputPending
            }
        };
    }

    Component.onCompleted: reconcile()

    property Connections providerChanges: Connections {
        target: root.provider

        function onRevisionChanged() {
            root.reconcile();
        }
    }

    property Timer flushTimer: Timer {
        interval: 16
        onTriggered: root.flush()
    }

    property Timer confirmationTimer: Timer {
        interval: 500
        onTriggered: root.expirePending()
    }
}
