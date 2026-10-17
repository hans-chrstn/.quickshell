.pragma library

function text(value) {
    return value === undefined || value === null ? "" : String(value);
}

function devicesForRole(nodes, role) {
    const requestedRole = text(role);
    if (requestedRole !== "output-device" && requestedRole !== "input-device")
        return [];

    const result = [];
    for (const node of nodes || []) {
        if (node?.role === requestedRole)
            result.push(node);
    }
    result.sort(function (left, right) {
        const availabilityDifference = Number(!!right?.ready) - Number(!!left?.ready);
        if (availabilityDifference !== 0)
            return availabilityDifference;
        const nameDifference = text(left?.displayName).localeCompare(text(right?.displayName));
        if (nameDifference !== 0)
            return nameDifference;
        return text(left?.stableKey).localeCompare(text(right?.stableKey));
    });
    return result;
}

function statusLabel(device) {
    if (!device?.ready)
        return "Unavailable";
    if (device?.isDefault)
        return "Default";
    if (device?.isPreferredDefault)
        return "Preferred";
    return "Available";
}

function cycleCandidates(nodes, role) {
    return devicesForRole(nodes, role).filter(device => device?.ready === true && device?.capabilities?.preferredDefaultWrite === true);
}

function cyclePlan(nodes, role, baseStableKey, direction) {
    if (role !== "output-device" && role !== "input-device")
        return {
            accepted: false,
            code: "invalid-role",
            message: "Audio device cycling requires an output or input role."
        };

    const candidates = cycleCandidates(nodes, role);
    if (candidates.length < 2)
        return {
            accepted: false,
            code: "insufficient-devices",
            message: "At least two controllable devices are required for cycling."
        };

    const baseKey = text(baseStableKey);
    let baseIndex = candidates.findIndex(device => text(device?.stableKey) === baseKey);
    if (baseIndex < 0)
        baseIndex = direction < 0 ? 0 : -1;
    const step = direction < 0 ? -1 : 1;
    const targetIndex = (baseIndex + step + candidates.length) % candidates.length;
    const target = candidates[targetIndex];
    return {
        accepted: true,
        code: "cycle-target",
        message: "",
        target: target,
        targetIndex: targetIndex,
        candidateCount: candidates.length
    };
}
