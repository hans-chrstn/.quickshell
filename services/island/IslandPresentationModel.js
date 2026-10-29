.pragma library

function normalizedName(value) {
    return String(value || "").trim();
}

function isZenEnabled(state, screenName) {
    const name = normalizedName(screenName);
    return name.length > 0 && state?.[name] === true;
}

function setZenEnabled(state, screenName, enabled) {
    const name = normalizedName(screenName);
    if (name.length === 0 || typeof enabled !== "boolean")
        return {
            accepted: false,
            changed: false,
            state: copyState(state)
        };

    const current = isZenEnabled(state, name);
    if (current === enabled)
        return {
            accepted: true,
            changed: false,
            state: copyState(state)
        };

    const updated = copyState(state);
    if (enabled)
        updated[name] = true;
    else
        delete updated[name];
    return {
        accepted: true,
        changed: true,
        state: updated
    };
}

function retainAvailable(state, availableNames) {
    const available = new Set(Array.isArray(availableNames) ? availableNames.map(normalizedName) : []);
    const updated = {};
    for (const name in state || {}) {
        if (state[name] === true && available.has(name))
            updated[name] = true;
    }
    return updated;
}

function enabledScreenNames(state) {
    const names = [];
    for (const name in state || {}) {
        if (state[name] === true)
            names.push(name);
    }
    names.sort();
    return names;
}

function copyState(state) {
    const copied = {};
    for (const name in state || {}) {
        if (state[name] === true)
            copied[name] = true;
    }
    return copied;
}
