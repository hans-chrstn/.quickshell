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

function streamBySessionId(group, sessionId) {
    const identity = text(sessionId).trim().slice(0, 256);
    if (identity.length === 0)
        return null;
    const streams = Array.isArray(group?.streams) ? group.streams : [];
    return streams.find(stream => text(stream?.sessionId) === identity) || null;
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

function uniqueSessionIds(group) {
    const identities = [];
    for (const stream of group?.streams || []) {
        const identity = text(stream?.sessionId).trim().slice(0, 256);
        if (identity.length > 0 && !identities.includes(identity))
            identities.push(identity);
    }
    return identities;
}

function sameSet(left, right) {
    const first = (left || []).map(value => text(value)).sort();
    const second = (right || []).map(value => text(value)).sort();
    return first.length === second.length && first.every((value, index) => value === second[index]);
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
    const sessionIds = uniqueSessionIds(group);
    if (nodeIds.length === 0 || nodeIds.length !== Number(group.streamCount) || sessionIds.length !== Number(group.streamCount))
        return rejected("stream-set-invalid", "The application stream set is incomplete.", groupKey, normalizedOperation);

    return {
        accepted: true,
        code: "accepted",
        message: "",
        groupKey: text(group.key),
        operation: normalizedOperation,
        role: group.direction === "input" ? "input" : "output",
        nodeIds: nodeIds,
        sessionIds: sessionIds,
        group: group
    };
}

function streamControlTarget(applications, groupKey, sessionId, operation) {
    const normalizedOperation = text(operation).trim().toLowerCase();
    if (normalizedOperation !== "volume" && normalizedOperation !== "mute")
        return rejected("invalid-operation", "Stream control must be volume or mute.", groupKey, operation);

    const group = groupByKey(applications, groupKey);
    if (!group)
        return rejected("application-ended", "The application is no longer producing an audio stream.", groupKey, normalizedOperation);
    if (!group.active || !group.ready)
        return rejected("application-unavailable", "The application audio stream is not ready for control.", groupKey, normalizedOperation);

    const stream = streamBySessionId(group, sessionId);
    if (!stream)
        return rejected("stream-ended", "The selected audio stream is no longer available.", groupKey, normalizedOperation);
    if (!stream.ready)
        return rejected("stream-unavailable", "The selected audio stream is not ready for control.", groupKey, normalizedOperation);
    if (stream.capabilities?.volumeWrite !== true || stream.capabilities?.muteWrite !== true)
        return rejected("control-unavailable", "This stream does not expose the requested audio control.", groupKey, normalizedOperation);

    const nodeId = Math.trunc(Number(stream.id));
    if (nodeId < 0)
        return rejected("stream-set-invalid", "The selected audio stream has no valid native node.", groupKey, normalizedOperation);

    return {
        accepted: true,
        code: "accepted",
        message: "",
        groupKey: text(group.key),
        sessionId: text(stream.sessionId),
        operation: normalizedOperation,
        role: group.direction === "input" ? "input" : "output",
        nodeIds: [nodeId],
        sessionIds: [text(stream.sessionId)],
        group: group,
        stream: stream
    };
}

function targetContinuity(group, pending) {
    if (!group)
        return rejected("application-ended", "The application ended before the sound change completed.", pending?.groupKey, pending?.operation);
    if (!group.active || !group.ready)
        return rejected("application-unavailable", "The application audio stream became unavailable before the sound change completed.", pending?.groupKey, pending?.operation);

    const role = group.direction === "input" ? "input" : "output";
    if (role !== text(pending?.role))
        return rejected("application-changed", "The application stream direction changed before the sound change completed.", pending?.groupKey, pending?.operation);

    if (pending?.scope === "stream") {
        const stream = streamBySessionId(group, pending?.sessionId);
        if (!stream)
            return rejected("stream-ended", "The selected audio stream ended before the sound change completed.", pending?.groupKey, pending?.operation);
        if (!stream.ready)
            return rejected("stream-unavailable", "The selected audio stream became unavailable before the sound change completed.", pending?.groupKey, pending?.operation);
        if (stream.capabilities?.volumeWrite !== true || stream.capabilities?.muteWrite !== true)
            return rejected("control-unavailable", "The selected audio stream stopped exposing sound controls.", pending?.groupKey, pending?.operation);
        if (!sameSet([stream.sessionId], pending?.sessionIds) || !sameSet([Math.trunc(Number(stream.id))], pending?.nodeIds))
            return rejected("stream-changed", "The selected audio stream was replaced before the sound change completed.", pending?.groupKey, pending?.operation);
    } else {
        if (group.capabilities?.volumeWrite !== true || group.capabilities?.muteWrite !== true)
            return rejected("control-unavailable", "The application stopped exposing sound controls.", pending?.groupKey, pending?.operation);
        if (!sameSet(uniqueSessionIds(group), pending?.sessionIds) || !sameSet(uniqueNodeIds(group), pending?.nodeIds))
            return rejected("stream-set-changed", "The application's audio streams changed before the sound change completed.", pending?.groupKey, pending?.operation);
    }

    return {
        accepted: true,
        code: "current",
        message: ""
    };
}

function targetMatches(group, pending, tolerance) {
    if (!group || !pending?.active)
        return false;
    const maximumDifference = Math.max(0.0001, Number(tolerance) || 0.01);
    const volumeMatches = Number.isFinite(Number(group.volume)) && Math.abs(Number(group.volume) - Number(pending.volume)) <= maximumDifference && !group.mixedVolume;
    return volumeMatches && group.muted === pending.muted && !group.mixedMute;
}

function streamTargetMatches(group, pending, tolerance) {
    if (!group || !pending?.active)
        return false;
    const stream = streamBySessionId(group, pending.sessionId);
    if (!stream)
        return false;
    const maximumDifference = Math.max(0.0001, Number(tolerance) || 0.01);
    const volumeMatches = Number.isFinite(Number(stream.volume)) && Math.abs(Number(stream.volume) - Number(pending.volume)) <= maximumDifference;
    return volumeMatches && stream.muted === pending.muted;
}
