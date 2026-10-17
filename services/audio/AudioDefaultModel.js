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

function deviceForKey(nodes, stableKey) {
    const key = text(stableKey);
    for (const node of nodes || []) {
        if (text(node?.stableKey) === key)
            return node;
    }
    return null;
}

function defaultKey(nodes, role, preferred) {
    const expectedRole = deviceRole(role);
    for (const node of nodes || []) {
        if (node?.role !== expectedRole)
            continue;
        if (preferred ? node?.isPreferredDefault === true : node?.isDefault === true)
            return text(node.stableKey);
    }
    return "";
}

function emptyState(role, nodes) {
    const normalized = normalizedRole(role);
    return {
        role: normalized,
        phase: "idle",
        requestedStableKey: "",
        requestedNodeId: -1,
        actualStableKey: defaultKey(nodes, normalized, false),
        preferredStableKey: defaultKey(nodes, normalized, true),
        code: "",
        message: "",
        sequence: 0
    };
}

function requestPlan(role, stableKey, nodes, backendReady) {
    const normalized = normalizedRole(role);
    const key = text(stableKey).trim();
    if (normalized.length === 0)
        return {
            accepted: false,
            code: "invalid-role",
            message: "Audio device role must be output or input."
        };
    if (!backendReady)
        return {
            accepted: false,
            code: "backend-unavailable",
            message: "PipeWire is not ready."
        };
    if (key.length === 0)
        return {
            accepted: false,
            code: "invalid-device",
            message: "A stable audio device identity is required."
        };

    const target = deviceForKey(nodes, key);
    if (!target)
        return {
            accepted: false,
            code: "device-unavailable",
            message: "The requested audio device is no longer available."
        };
    if (target.role !== deviceRole(normalized))
        return {
            accepted: false,
            code: "role-mismatch",
            message: "The requested device does not match the " + normalized + " role."
        };
    if (!target.ready)
        return {
            accepted: false,
            code: "device-not-ready",
            message: "The requested audio device is not ready."
        };
    if (target.capabilities?.preferredDefaultWrite !== true)
        return {
            accepted: false,
            code: "control-unavailable",
            message: "The requested audio device cannot become the preferred default."
        };

    return {
        accepted: true,
        code: target.isDefault ? "unchanged" : "accepted",
        message: "",
        role: normalized,
        target: target
    };
}

function requestedState(role, target, sequence, nodes) {
    const normalized = normalizedRole(role);
    return {
        role: normalized,
        phase: target?.isDefault === true ? "confirmed" : "requested",
        requestedStableKey: text(target?.stableKey),
        requestedNodeId: Number(target?.id) || -1,
        actualStableKey: defaultKey(nodes, normalized, false),
        preferredStableKey: defaultKey(nodes, normalized, true),
        code: target?.isDefault === true ? "unchanged" : "awaiting-preference",
        message: "",
        sequence: Math.max(0, Math.floor(Number(sequence) || 0))
    };
}

function reconciledState(state, nodes) {
    const role = normalizedRole(state?.role);
    const key = text(state?.requestedStableKey);
    if (role.length === 0 || key.length === 0)
        return emptyState(role, nodes);

    const target = deviceForKey(nodes, key);
    const result = Object.assign({}, state, {
        actualStableKey: defaultKey(nodes, role, false),
        preferredStableKey: defaultKey(nodes, role, true)
    });
    if (!target) {
        result.phase = "failed";
        result.code = "device-unavailable";
        result.message = "The requested audio device disappeared before confirmation.";
    } else if (target.isDefault) {
        result.phase = "confirmed";
        result.code = "confirmed";
        result.message = "";
        result.requestedNodeId = Number(target.id) || -1;
    } else if (target.isPreferredDefault) {
        result.phase = "preferred";
        result.code = "effective-pending";
        result.message = "PipeWire accepted the preference, but the effective default has not changed.";
        result.requestedNodeId = Number(target.id) || -1;
    } else if (state?.phase !== "requested") {
        result.phase = "superseded";
        result.code = "preference-superseded";
        result.message = "Another audio preference replaced this request.";
    }
    return result;
}

function timedOutState(state, nodes) {
    const reconciled = reconciledState(state, nodes);
    if (reconciled.phase !== "requested")
        return reconciled;
    return Object.assign({}, reconciled, {
        phase: "failed",
        code: "confirmation-timeout",
        message: "PipeWire did not confirm the preferred device within the bounded wait."
    });
}
