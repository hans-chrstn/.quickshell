.pragma library

function normalizedRole(role) {
    const value = String(role || "").trim().toLowerCase();
    return value === "output" || value === "input" ? value : "";
}

function boundedNumber(value, minimum, maximum, fallback) {
    const numeric = Number(value);
    return Number.isFinite(numeric) ? Math.max(minimum, Math.min(maximum, numeric)) : fallback;
}

function normalizedPolicy(options) {
    const source = options || ({});
    return {
        step: boundedNumber(source.step, 0.01, 0.2, 0.05),
        outputCeiling: boundedNumber(source.outputCeiling, 1, 1.5, 1),
        inputCeiling: boundedNumber(source.inputCeiling, 1, 1.5, 1),
        muteAtZero: source.muteAtZero === undefined ? true : Boolean(source.muteAtZero),
        restoreOnUnmute: source.restoreOnUnmute === undefined ? true : Boolean(source.restoreOnUnmute)
    };
}

function ceilingForRole(role, policy) {
    return role === "input" ? policy.inputCeiling : policy.outputCeiling;
}

function rejected(code, message, role, requestedValue) {
    return {
        accepted: false,
        code: code,
        message: message,
        role: normalizedRole(role),
        requestedValue: requestedValue,
        value: null
    };
}

function volumeRequest(role, value, ceiling) {
    const normalized = normalizedRole(role);
    if (normalized.length === 0)
        return rejected("invalid-role", "Audio role must be output or input.", role, value);

    const requested = Number(value);
    if (!Number.isFinite(requested))
        return rejected("invalid-volume", "Volume must be a finite number.", normalized, value);

    const maximum = Math.max(0, Number.isFinite(Number(ceiling)) ? Number(ceiling) : 1);
    return {
        accepted: true,
        code: "accepted",
        message: "",
        role: normalized,
        requestedValue: requested,
        value: Math.max(0, Math.min(maximum, requested))
    };
}

function muteRequest(role, muted) {
    const normalized = normalizedRole(role);
    if (normalized.length === 0)
        return rejected("invalid-role", "Audio role must be output or input.", role, muted);
    if (typeof muted !== "boolean")
        return rejected("invalid-mute", "Mute state must be a boolean.", normalized, muted);
    return {
        accepted: true,
        code: "accepted",
        message: "",
        role: normalized,
        requestedValue: muted,
        value: muted
    };
}

function volumePlan(role, requestedVolume, rememberedVolume, options) {
    const policy = normalizedPolicy(options);
    const request = volumeRequest(role, requestedVolume, ceilingForRole(normalizedRole(role), policy));
    if (!request.accepted)
        return request;

    const targetVolume = request.value;
    return Object.assign({}, request, {
        operation: "volume",
        volume: targetVolume,
        muted: targetVolume <= 0 ? policy.muteAtZero : false,
        rememberedVolume: targetVolume > 0 ? targetVolume : boundedNumber(rememberedVolume, 0, ceilingForRole(request.role, policy), 0),
        clamped: targetVolume !== request.requestedValue
    });
}

function mutePlan(role, currentVolume, currentMuted, requestedMuted, rememberedVolume, options) {
    const policy = normalizedPolicy(options);
    const request = muteRequest(role, requestedMuted);
    if (!request.accepted)
        return request;

    const ceiling = ceilingForRole(request.role, policy);
    const current = boundedNumber(currentVolume, 0, ceiling, 0);
    let targetVolume = current;
    if (!request.value && current <= 0 && policy.restoreOnUnmute) {
        const remembered = boundedNumber(rememberedVolume, 0, ceiling, 0);
        targetVolume = remembered > 0 ? remembered : policy.step;
    }
    return Object.assign({}, request, {
        operation: "mute",
        volume: targetVolume,
        muted: request.value,
        rememberedVolume: targetVolume > 0 ? targetVolume : 0,
        clamped: false
    });
}

function adjustmentPlan(role, currentVolume, currentMuted, steps, rememberedVolume, options) {
    const normalized = normalizedRole(role);
    if (normalized.length === 0)
        return rejected("invalid-role", "Audio role must be output or input.", role, steps);
    const count = Number(steps);
    if (!Number.isFinite(count) || count === 0)
        return rejected("invalid-adjustment", "Adjustment steps must be a non-zero finite number.", normalized, steps);

    const policy = normalizedPolicy(options);
    const ceiling = ceilingForRole(normalized, policy);
    const current = boundedNumber(currentVolume, 0, ceiling, 0);
    let base = current;
    if (count > 0 && currentMuted && current <= 0 && policy.restoreOnUnmute) {
        const remembered = boundedNumber(rememberedVolume, 0, ceiling, 0);
        base = remembered > 0 ? remembered : 0;
    }
    return volumePlan(normalized, base + count * policy.step, rememberedVolume, policy);
}
