.pragma library

function text(value) {
    return value === undefined || value === null ? "" : String(value).trim();
}

function microphoneClientKeys(state) {
    const keys = new Set();
    for (const path of Array.isArray(state?.paths) ? state.paths : []) {
        if (path?.microphone === true) {
            const key = text(path.clientKey);
            if (key.length > 0)
                keys.add(key);
        }
    }
    return keys;
}

function microphoneClients(state) {
    const keys = microphoneClientKeys(state);
    return (Array.isArray(state?.clients) ? state.clients : []).filter(client => keys.has(text(client?.key))).map(client => ({
                key: text(client?.key),
                displayName: text(client?.displayName) || "Unknown application",
                identified: client?.identified === true
            })).sort((left, right) => left.displayName.localeCompare(right.displayName) || left.key.localeCompare(right.key));
}

function presentation(state) {
    const active = state?.microphoneActive === true;
    if (!active) {
        return {
            active: false,
            clientCount: 0,
            primaryName: "",
            title: "",
            detail: ""
        };
    }
    const clients = active ? microphoneClients(state) : [];
    const count = clients.length;
    const primaryName = count > 0 ? clients[0].displayName : "Unknown application";
    return {
        active: active,
        clientCount: count,
        primaryName: primaryName,
        title: count > 1 ? primaryName + " +" + (count - 1) : primaryName,
        detail: count > 1 ? count + " apps using microphone" : "Using microphone"
    };
}
