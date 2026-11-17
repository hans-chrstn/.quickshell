.pragma library

const slots = ["island", "rail"];

function copyEntry(entry) {
    return {
        island: String(entry?.island || ""),
        rail: String(entry?.rail || "")
    };
}

function select(state, availableScreens, screenName, slot, route) {
    const screen = String(screenName || "").trim();
    const normalizedSlot = String(slot || "").trim();
    const normalizedRoute = String(route || "").trim();
    const available = new Set(Array.isArray(availableScreens) ? availableScreens.map(name => String(name || "").trim()) : []);
    if (!available.has(screen) || !slots.includes(normalizedSlot))
        return {
            accepted: false,
            state: reconcile(state, availableScreens)
        };

    const next = reconcile(state, availableScreens);
    const entry = copyEntry(next[screen]);
    entry[normalizedSlot] = normalizedRoute;
    if (entry.island.length > 0 || entry.rail.length > 0)
        next[screen] = entry;
    else
        delete next[screen];
    return {
        accepted: true,
        state: next
    };
}

function reconcile(state, availableScreens) {
    const available = new Set(Array.isArray(availableScreens) ? availableScreens.map(name => String(name || "").trim()) : []);
    const next = {};
    for (const screen in state || {}) {
        if (!available.has(screen))
            continue;
        const entry = copyEntry(state[screen]);
        if (entry.island.length > 0 || entry.rail.length > 0)
            next[screen] = entry;
    }
    return next;
}

function routeFor(state, screenName, slot) {
    if (!slots.includes(slot))
        return "";
    return String(state?.[screenName]?.[slot] || "");
}
