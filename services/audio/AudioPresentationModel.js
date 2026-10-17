.pragma library

var minimumDurationMs = 1000;
var maximumDurationMs = 4000;
var defaultDurationMs = 1800;

function normalizedRole(role) {
    const value = String(role || "").trim().toLowerCase();
    return value === "output" || value === "input" ? value : "";
}

function normalizedChange(change, screenName, nowMs, durationMs) {
    const source = change || ({});
    const role = normalizedRole(source.role);
    const volume = Number(source.volume);
    const muted = source.muted;
    const fields = Array.isArray(source.changedFields) ? source.changedFields.filter(field => field === "volume" || field === "muted") : [];
    if (role.length === 0 || !Number.isFinite(volume) || typeof muted !== "boolean" || fields.length === 0)
        return null;
    const requestedDuration = Number(durationMs);
    const boundedDuration = Number.isFinite(requestedDuration) ? Math.max(minimumDurationMs, Math.min(maximumDurationMs, Math.round(requestedDuration))) : defaultDurationMs;
    return {
        sequence: Math.max(0, Number(source.sequence) || 0),
        source: source.source === "external" ? "external" : "local",
        role: role,
        operation: String(source.operation || "state"),
        changedFields: fields,
        volume: Math.max(0, volume),
        muted: muted,
        deviceKey: String(source.deviceKey || ""),
        deviceName: String(source.deviceName || "").trim().slice(0, 96),
        screenName: String(screenName || "").trim().slice(0, 128),
        createdAtMs: Math.max(0, Number(nowMs) || 0),
        durationMs: boundedDuration
    };
}

function percent(change) {
    return Math.max(0, Math.round((Number(change?.volume) || 0) * 100));
}

function iconName(change) {
    if (change?.role === "input")
        return change.muted ? "microphoneMuted" : "microphone";
    if (change?.muted || percent(change) === 0)
        return "volumeMuted";
    return percent(change) > 45 ? "volumeHigh" : "volumeLow";
}

function valueText(change) {
    return change?.muted ? "Muted" : percent(change) + "%";
}
