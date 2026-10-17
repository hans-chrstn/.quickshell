.pragma library

function text(value) {
    return value === undefined || value === null ? "" : String(value);
}

function groups(applications) {
    const source = applications || ({});
    const playing = Array.isArray(source.playing) ? source.playing : [];
    const recording = Array.isArray(source.recording) ? source.recording : [];
    return playing.concat(recording);
}

function groupByKey(applications, groupKey) {
    const key = text(groupKey).trim().slice(0, 256);
    if (key.length === 0)
        return null;
    return groups(applications).find(group => text(group?.key) === key) || null;
}

function rejected(code, message, groupKey, operation) {
    return {
        accepted: false,
        code: code,
        message: message,
        groupKey: text(groupKey),
        operation: text(operation),
        role: "",
        nodeIds: []
    };
}

function uniqueNodeIds(group) {
    const ids = [];
    for (const value of group?.streamNodeIds || []) {
        const id = Math.trunc(Number(value));
        if (id >= 0 && !ids.includes(id))
            ids.push(id);
    }
    return ids;
}

function controlTarget(applications, groupKey, operation) {
    const normalizedOperation = text(operation).trim().toLowerCase();
    if (normalizedOperation !== "volume" && normalizedOperation !== "mute")
        return rejected("invalid-operation", "Application control must be volume or mute.", groupKey, operation);

    const group = groupByKey(applications, groupKey);
    if (!group)
        return rejected("application-ended", "The application is no longer producing an audio stream.", groupKey, normalizedOperation);
    if (!group.active || !group.ready)
        return rejected("application-unavailable", "The application audio stream is not ready for control.", groupKey, normalizedOperation);

    if (group.capabilities?.volumeWrite !== true || group.capabilities?.muteWrite !== true)
        return rejected("control-unavailable", "This application does not expose the requested audio control.", groupKey, normalizedOperation);

    const nodeIds = uniqueNodeIds(group);
    if (nodeIds.length === 0 || nodeIds.length !== Number(group.streamCount))
        return rejected("stream-set-invalid", "The application stream set is incomplete.", groupKey, normalizedOperation);

    return {
        accepted: true,
        code: "accepted",
        message: "",
        groupKey: text(group.key),
        operation: normalizedOperation,
        role: group.direction === "input" ? "input" : "output",
        nodeIds: nodeIds,
        group: group
    };
}

function targetMatches(group, pending, tolerance) {
    if (!group || !pending?.active)
        return false;
    const maximumDifference = Math.max(0.0001, Number(tolerance) || 0.01);
    const volumeMatches = Number.isFinite(Number(group.volume)) && Math.abs(Number(group.volume) - Number(pending.volume)) <= maximumDifference && !group.mixedVolume;
    return volumeMatches && group.muted === pending.muted && !group.mixedMute;
}
