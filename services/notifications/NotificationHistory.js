.pragma library

var maximumEntries = 120;
var maximumAgeMs = 7 * 24 * 60 * 60 * 1000;

function sanitize(entry, nowMs) {
    if (!entry || typeof entry !== "object")
        return null;
    const id = String(entry.id || "").slice(0, 128);
    const title = String(entry.title || "").slice(0, 80);
    const createdAtMs = Number(entry.createdAtMs);
    const latestAtMs = Number(entry.latestAtMs ?? createdAtMs);
    if (!id || !title || !Number.isFinite(createdAtMs) || !Number.isFinite(latestAtMs) || latestAtMs < nowMs - maximumAgeMs || latestAtMs > nowMs + 60000)
        return null;
    return {
        id: id,
        title: title,
        message: String(entry.message || "").slice(0, 360),
        source: String(entry.source || "").slice(0, 64),
        severity: ["info", "success", "warning", "error"].includes(entry.severity) ? entry.severity : "info",
        screenName: String(entry.screenName || "").slice(0, 128),
        occurrenceCount: Math.max(1, Math.min(999, Number(entry.occurrenceCount) || 1)),
        createdAtMs: createdAtMs,
        latestAtMs: latestAtMs
    };
}

function merge(stored, current, nowMs) {
    const byId = new Map();
    for (const candidate of [...(Array.isArray(stored) ? stored : []), ...(Array.isArray(current) ? current : [])]) {
        const item = sanitize(candidate, nowMs);
        if (!item)
            continue;
        if (!byId.has(item.id) || byId.get(item.id).latestAtMs <= item.latestAtMs)
            byId.set(item.id, item);
    }
    return [...byId.values()].sort((left, right) => right.latestAtMs - left.latestAtMs || right.createdAtMs - left.createdAtMs).slice(0, maximumEntries);
}

function insert(history, notice, nowMs) {
    return merge(history, [Object.assign({}, notice, {
            latestAtMs: nowMs
        })], nowMs);
}

function remove(history, id) {
    return (Array.isArray(history) ? history : []).filter(item => item.id !== id);
}

function groups(history) {
    const result = [];
    const byKey = new Map();
    for (const item of Array.isArray(history) ? history : []) {
        const key = (item.source ? "source:" + item.source : "title:" + item.title).toLocaleLowerCase();
        let group = byKey.get(key);
        if (!group) {
            group = {
                key: key,
                source: item.source,
                title: item.title,
                severity: item.severity,
                items: [],
                count: 0,
                latestAtMs: item.latestAtMs
            };
            byKey.set(key, group);
            result.push(group);
        }
        group.items.push(item);
        group.count += item.occurrenceCount;
    }
    return result;
}

function lockSafe(history) {
    return (Array.isArray(history) ? history : []).map(item => ({
                id: item.id,
                title: item.title,
                source: item.source,
                severity: item.severity,
                occurrenceCount: item.occurrenceCount,
                latestAtMs: item.latestAtMs
            }));
}
