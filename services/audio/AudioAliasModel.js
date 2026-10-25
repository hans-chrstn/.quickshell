.pragma library

const maximumAliasLength = 64;
const maximumAliasCount = 128;

function text(value) {
    return value === undefined || value === null ? "" : String(value);
}

function normalizedStableKey(value) {
    const key = text(value).trim().slice(0, 256);
    if (!key.startsWith("output-device:") && !key.startsWith("input-device:"))
        return "";
    return key;
}

function normalizedAlias(value) {
    return text(value).replace(/[\u0000-\u001f\u007f]/g, " ").replace(/\s+/g, " ").trim().slice(0, maximumAliasLength);
}

function normalizedAliases(values) {
    const result = ({});
    if (!values || typeof values !== "object" || Array.isArray(values))
        return result;

    const keys = Object.keys(values).sort();
    for (const rawKey of keys) {
        if (Object.keys(result).length >= maximumAliasCount)
            break;
        const key = normalizedStableKey(rawKey);
        const alias = normalizedAlias(values[rawKey]);
        if (key.length > 0 && alias.length > 0)
            result[key] = alias;
    }
    return result;
}

function aliasFor(aliases, stableKey) {
    const key = normalizedStableKey(stableKey);
    return key.length > 0 ? text(aliases?.[key]) : "";
}

function displayName(device, aliases) {
    return aliasFor(aliases, device?.stableKey) || text(device?.displayName) || "Unknown audio device";
}

function deviceForKey(nodes, stableKey) {
    const key = normalizedStableKey(stableKey);
    for (const node of nodes || []) {
        if (text(node?.stableKey) === key && (node?.role === "output-device" || node?.role === "input-device"))
            return node;
    }
    return null;
}

function requestPlan(nodes, aliases, stableKey, requestedAlias) {
    const key = normalizedStableKey(stableKey);
    if (key.length === 0)
        return {
            accepted: false,
            code: "invalid-device",
            message: "A stable physical audio-device identity is required."
        };

    const device = deviceForKey(nodes, key);
    if (!device)
        return {
            accepted: false,
            code: "device-unavailable",
            message: "The audio device is no longer available."
        };

    const rawAlias = text(requestedAlias).trim();
    if (rawAlias.length > maximumAliasLength)
        return {
            accepted: false,
            code: "alias-too-long",
            message: "Device names can contain at most " + maximumAliasLength + " characters."
        };
    if (/[\u0000-\u001f\u007f]/.test(rawAlias))
        return {
            accepted: false,
            code: "invalid-alias",
            message: "Device names cannot contain control characters."
        };

    const alias = normalizedAlias(rawAlias);
    const updated = normalizedAliases(aliases);
    if (alias.length > 0)
        updated[key] = alias;
    else
        delete updated[key];

    return {
        accepted: true,
        code: alias.length > 0 ? "alias-set" : "alias-cleared",
        message: "",
        stableKey: key,
        alias: alias,
        aliases: updated,
        originalName: text(device.displayName)
    };
}
