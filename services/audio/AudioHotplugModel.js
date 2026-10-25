.pragma library

function text(value) {
    return value === undefined || value === null ? "" : String(value);
}

function normalizedRole(role) {
    const value = text(role);
    return value === "output" || value === "input" ? value : "";
}

function deviceRole(role) {
    const value = normalizedRole(role);
    return value.length > 0 ? value + "-device" : "";
}

function readyDevices(records, role) {
    const expectedRole = deviceRole(role);
    const result = [];
    for (const record of records || []) {
        if (record?.role !== expectedRole || record?.ready !== true)
            continue;
        result.push({
            stableKey: text(record.stableKey),
            name: text(record.displayName || record.name || "Audio device"),
            nodeId: Number(record.id) || -1
        });
    }
    result.sort((left, right) => left.stableKey.localeCompare(right.stableKey));
    return result;
}

function defaultRecord(value) {
    if (!value || value.ready !== true)
        return {
            stableKey: "",
            name: "",
            nodeId: -1
        };
    return {
        stableKey: text(value.stableKey),
        name: text(value.name || "Audio device"),
        nodeId: Number(value.id) || -1
    };
}

function emptyEvent() {
    return {
        kind: "",
        role: "",
        fromStableKey: "",
        fromName: "",
        toStableKey: "",
        toName: "",
        message: "",
        sequence: 0
    };
}

function emptyState(role) {
    return {
        initialized: false,
        role: normalizedRole(role),
        availableKeys: [],
        defaultStableKey: "",
        defaultName: "",
        displacedStableKey: "",
        displacedName: "",
        displacedFallbackObserved: false,
        event: emptyEvent(),
        sequence: 0
    };
}

function namedDevice(devices, stableKey, fallbackName) {
    const key = text(stableKey);
    for (const device of devices || []) {
        if (device.stableKey === key)
            return device.name;
    }
    return text(fallbackName || "Audio device");
}

function messageFor(kind, role, fromName, toName) {
    const target = role === "input" ? "input" : "output";
    if (kind === "fallback")
        return fromName + " disconnected · using " + toName;
    if (kind === "disconnected")
        return fromName + " disconnected · no " + target + " available";
    if (kind === "restored")
        return fromName + " reconnected · restored by PipeWire";
    if (kind === "available-again")
        return fromName + " reconnected · staying on " + (toName || "the current " + target);
    return "";
}

function event(kind, role, fromKey, fromName, toKey, toName, sequence) {
    return {
        kind: kind,
        role: role,
        fromStableKey: text(fromKey),
        fromName: text(fromName),
        toStableKey: text(toKey),
        toName: text(toName),
        message: messageFor(kind, role, text(fromName), text(toName)),
        sequence: sequence
    };
}

function reconcile(previousState, records, currentDefault) {
    const previous = previousState || emptyState("");
    const role = normalizedRole(previous.role);
    if (role.length === 0)
        return emptyState(role);

    const devices = readyDevices(records, role);
    const availableKeys = devices.map(device => device.stableKey);
    const current = defaultRecord(currentDefault);
    const base = Object.assign({}, previous, {
        initialized: true,
        availableKeys: availableKeys,
        defaultStableKey: current.stableKey,
        defaultName: current.name
    });
    if (!previous.initialized)
        return base;

    const previousDefaultWasPhysical = previous.defaultStableKey.length > 0 && previous.availableKeys.includes(previous.defaultStableKey);
    const previousDefaultMissing = previousDefaultWasPhysical && !availableKeys.includes(previous.defaultStableKey);
    if (previousDefaultMissing) {
        const sequence = previous.sequence + 1;
        const fromName = namedDevice([], previous.defaultStableKey, previous.defaultName);
        const kind = current.stableKey.length > 0 ? "fallback" : "disconnected";
        return Object.assign({}, base, {
            displacedStableKey: previous.defaultStableKey,
            displacedName: fromName,
            displacedFallbackObserved: current.stableKey.length > 0,
            sequence: sequence,
            event: event(kind, role, previous.defaultStableKey, fromName, current.stableKey, current.name, sequence)
        });
    }

    if (previous.displacedStableKey.length > 0) {
        const returned = availableKeys.includes(previous.displacedStableKey);
        if (returned) {
            const sequence = previous.sequence + 1;
            const restored = current.stableKey === previous.displacedStableKey;
            const fromName = namedDevice(devices, previous.displacedStableKey, previous.displacedName);
            const kind = restored ? "restored" : "available-again";
            return Object.assign({}, base, {
                displacedStableKey: "",
                displacedName: "",
                displacedFallbackObserved: false,
                sequence: sequence,
                event: event(kind, role, previous.displacedStableKey, fromName, current.stableKey, current.name, sequence)
            });
        }

        if (!previous.displacedFallbackObserved && current.stableKey.length > 0) {
            const sequence = previous.sequence + 1;
            return Object.assign({}, base, {
                displacedFallbackObserved: true,
                sequence: sequence,
                event: event("fallback", role, previous.displacedStableKey, previous.displacedName, current.stableKey, current.name, sequence)
            });
        }
    }

    return base;
}
