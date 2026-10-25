.pragma library

var volumeTolerance = 0.002;

function finiteVolume(value) {
    const numeric = Number(value);
    return Number.isFinite(numeric) ? numeric : null;
}

function normalizedRecord(role, record) {
    const source = record || ({});
    const available = source.available === true;
    return {
        role: role,
        available: available,
        id: available ? Number(source.id) : -1,
        key: available ? String(source.key || "") : "",
        name: available ? String(source.name || "") : "",
        ready: available && source.ready === true,
        volume: available ? finiteVolume(source.volume) : null,
        muted: available && typeof source.muted === "boolean" ? source.muted : null,
        capabilities: source.capabilities || ({})
    };
}

function sameDevice(left, right) {
    const first = left || ({});
    const second = right || ({});
    if (first.available !== true || second.available !== true)
        return first.available !== true && second.available !== true;
    return String(first.key || "") === String(second.key || "") && Number(first.id) === Number(second.id);
}

function sameState(left, right) {
    if (!sameDevice(left, right))
        return false;
    if (left?.available !== true)
        return true;
    const leftVolume = finiteVolume(left.volume);
    const rightVolume = finiteVolume(right.volume);
    return leftVolume !== null && rightVolume !== null && Math.abs(leftVolume - rightVolume) <= volumeTolerance && left.muted === right.muted;
}

function targetMatches(record, target) {
    const current = record || ({});
    const expected = target || ({});
    return sameDevice(current, expected) && current.ready === true && Math.abs(Number(current.volume) - Number(expected.volume)) <= volumeTolerance && current.muted === expected.muted;
}

function changedFields(previous, current) {
    const before = previous || ({});
    const after = current || ({});
    const fields = [];
    if (Math.abs(Number(before.volume) - Number(after.volume)) > volumeTolerance)
        fields.push("volume");
    if (before.muted !== after.muted)
        fields.push("muted");
    return fields;
}

function effectiveRecord(role, nativeRecord, pending) {
    const current = normalizedRecord(role, nativeRecord);
    if (pending?.active !== true || !sameDevice(current, pending))
        return current;
    return Object.assign({}, current, {
        volume: pending.volume,
        muted: pending.muted,
        optimistic: true,
        pendingPhase: String(pending.phase || "queued")
    });
}

function semanticEvent(sequence, source, operation, previous, current) {
    const after = current || ({});
    return {
        sequence: Number(sequence) || 0,
        source: String(source || ""),
        role: String(after.role || ""),
        operation: String(operation || "state"),
        changedFields: changedFields(previous, after),
        volume: finiteVolume(after.volume),
        muted: typeof after.muted === "boolean" ? after.muted : null,
        deviceKey: String(after.key || ""),
        deviceName: String(after.name || ""),
        occurredAtMs: Date.now()
    };
}
