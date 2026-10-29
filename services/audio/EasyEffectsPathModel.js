.pragma library

function text(value) {
    return value === undefined || value === null ? "" : String(value).trim();
}

function integer(value) {
    const number = Number(value);
    return Number.isFinite(number) ? Math.max(0, Math.trunc(number)) : 0;
}

function propertyText(node, key) {
    return text(node?.properties?.[key]);
}

function role(value) {
    const normalized = text(value).toLowerCase();
    return normalized === "output" || normalized === "input" ? normalized : "";
}

function directionMatches(node, roleValue) {
    const target = role(roleValue);
    const mediaClass = propertyText(node, "media.class").toLowerCase();
    if (target === "output")
        return node?.isSink === true || mediaClass.startsWith("audio/sink");
    if (target === "input")
        return node?.isSink === false || mediaClass.startsWith("audio/source");
    return false;
}

function isEasyEffectsVirtual(node, roleValue) {
    if (!node || node?.isStream === true || !directionMatches(node, roleValue))
        return false;
    const name = text(node?.name || propertyText(node, "node.name")).toLowerCase();
    const applicationId = propertyText(node, "application.id").toLowerCase();
    const virtual = propertyText(node, "node.virtual").toLowerCase();
    const easyEffects = name === "easyeffects_sink" || name === "easyeffects_source" || applicationId === "com.github.wwmm.easyeffects";
    return easyEffects && (virtual === "true" || name.startsWith("easyeffects_"));
}

function isPhysicalTarget(node, roleValue) {
    if (!node || node?.isStream === true || node?.ready !== true || !node?.audio || !directionMatches(node, roleValue))
        return false;
    const virtual = propertyText(node, "node.virtual").toLowerCase();
    const deviceApi = propertyText(node, "device.api");
    const name = text(node?.name || propertyText(node, "node.name")).toLowerCase();
    return virtual !== "true" && (deviceApi.length > 0 || name.startsWith("alsa_") || name.startsWith("bluez_"));
}

function resolution(roleValue, defaultNode, nodes) {
    const target = role(roleValue);
    const defaultId = integer(defaultNode?.id);
    if (target.length === 0)
        return result(target, defaultId, 0, false, "invalid-role");
    if (!defaultNode || defaultId <= 0)
        return result(target, 0, 0, false, "default-unavailable");
    if (!isEasyEffectsVirtual(defaultNode, target))
        return result(target, defaultId, defaultId, false, "direct");
    const driverId = integer(propertyText(defaultNode, "node.driver-id"));
    if (driverId <= 0 || driverId === defaultId)
        return result(target, defaultId, defaultId, true, driverId === defaultId ? "virtual-self-driver" : "virtual-driver-unavailable");
    const candidate = (nodes || []).find(node => integer(node?.id) === driverId);
    if (!isPhysicalTarget(candidate, target))
        return result(target, defaultId, defaultId, true, "virtual-driver-unavailable");
    return result(target, defaultId, driverId, true, "mapped-driver");
}

function result(roleValue, defaultId, targetId, virtualDefault, code) {
    return {
        role: roleValue,
        defaultId: defaultId,
        targetId: targetId,
        virtualDefault: virtualDefault,
        mapped: code === "mapped-driver",
        code: code
    };
}
