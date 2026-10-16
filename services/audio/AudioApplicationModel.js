.pragma library

function text(value) {
    return value === undefined || value === null ? "" : String(value);
}

function bounded(value, limit) {
    return text(value).trim().slice(0, limit);
}

function roleSection(role) {
    if (role === "playback-stream")
        return "playing";
    if (role === "recording-stream")
        return "recording";
    return "";
}

function streamIdentity(record) {
    const applicationKey = bounded(record?.applicationKey, 192);
    if (applicationKey.length > 0)
        return applicationKey;
    const sessionId = bounded(record?.sessionId || record?.stableKey, 192);
    if (sessionId.length > 0)
        return "unidentified:" + sessionId;
    return "unidentified:node:" + Math.max(0, Math.trunc(Number(record?.id) || 0));
}

function displayName(records) {
    const candidates = [];
    for (const record of records || []) {
        const applicationName = bounded(record?.applicationName, 160);
        const binary = bounded(record?.applicationBinary, 160);
        const fallback = bounded(record?.displayName || record?.name, 160);
        if (applicationName.length > 0)
            candidates.push({
                rank: 0,
                value: applicationName
            });
        if (binary.length > 0)
            candidates.push({
                rank: 1,
                value: binary
            });
        if (fallback.length > 0)
            candidates.push({
                rank: 2,
                value: fallback
            });
    }
    candidates.sort((left, right) => left.rank - right.rank || left.value.localeCompare(right.value));
    return candidates[0]?.value || "Unknown application";
}

function iconName(records) {
    const candidates = [];
    for (const record of records || []) {
        const candidate = bounded(record?.iconName, 192);
        if (candidate.length > 0 && !candidates.includes(candidate))
            candidates.push(candidate);
    }
    candidates.sort((left, right) => left.localeCompare(right));
    return candidates[0] || "";
}

function compactStream(record) {
    return {
        id: Math.max(0, Math.trunc(Number(record?.id) || 0)),
        sessionId: bounded(record?.sessionId || record?.stableKey, 192),
        displayName: bounded(record?.displayName || record?.name, 160),
        ready: !!record?.ready,
        volume: Number.isFinite(Number(record?.volume)) ? Number(record.volume) : null,
        muted: record?.muted === null || record?.muted === undefined ? null : !!record.muted,
        capabilities: Object.assign({}, record?.capabilities || ({}))
    };
}

function average(values) {
    if (values.length === 0)
        return null;
    const total = values.reduce((sum, value) => sum + value, 0);
    return Math.round(total / values.length * 1000000) / 1000000;
}

function allCapable(streams, capability) {
    return streams.length > 0 && streams.every(stream => stream.ready && stream.capabilities?.[capability] === true);
}

function groupRecord(role, identity, records) {
    const section = roleSection(role);
    const streams = records.map(compactStream).sort((left, right) => left.sessionId.localeCompare(right.sessionId) || left.id - right.id);
    const volumes = streams.map(stream => stream.volume).filter(value => Number.isFinite(value));
    const muteValues = streams.map(stream => stream.muted).filter(value => value !== null);
    const minimumVolume = volumes.length > 0 ? Math.min(...volumes) : null;
    const maximumVolume = volumes.length > 0 ? Math.max(...volumes) : null;
    const allMuted = muteValues.length === streams.length && muteValues.every(Boolean);
    const someMuted = muteValues.some(Boolean);

    return {
        key: role + ":" + identity,
        applicationKey: identity.startsWith("unidentified:") ? "" : identity,
        identityKind: bounded(records[0]?.applicationIdentityKind, 48) || "none",
        section: section,
        direction: section === "playing" ? "output" : "input",
        displayName: displayName(records),
        iconName: iconName(records),
        ready: streams.length > 0 && streams.every(stream => stream.ready),
        active: streams.length > 0,
        streamCount: streams.length,
        streamNodeIds: streams.map(stream => stream.id),
        streamSessionIds: streams.map(stream => stream.sessionId),
        volume: average(volumes),
        mixedVolume: volumes.length > 1 && maximumVolume - minimumVolume > 0.005,
        muted: allMuted,
        mixedMute: someMuted && !allMuted,
        capabilities: {
            volumeRead: allCapable(streams, "volumeRead"),
            volumeWrite: allCapable(streams, "volumeWrite"),
            muteRead: allCapable(streams, "muteRead"),
            muteWrite: allCapable(streams, "muteWrite"),
            routeRead: allCapable(streams, "routeRead"),
            routeWrite: allCapable(streams, "routeWrite")
        },
        streams: streams
    };
}

function groupedApplications(records) {
    const buckets = ({});
    for (const record of records || []) {
        const role = text(record?.role);
        if (roleSection(role).length === 0)
            continue;
        const identity = streamIdentity(record);
        const key = role + ":" + identity;
        if (!Array.isArray(buckets[key]))
            buckets[key] = [];
        buckets[key].push(record);
    }

    const playing = [];
    const recording = [];
    for (const key of Object.keys(buckets)) {
        const separator = key.indexOf(":");
        const role = key.slice(0, separator);
        const identity = key.slice(separator + 1);
        const group = groupRecord(role, identity, buckets[key]);
        if (group.section === "playing")
            playing.push(group);
        else
            recording.push(group);
    }

    const compareGroups = (left, right) => left.displayName.localeCompare(right.displayName) || left.key.localeCompare(right.key);
    playing.sort(compareGroups);
    recording.sort(compareGroups);
    return {
        playing: playing,
        recording: recording,
        playingCount: playing.length,
        recordingCount: recording.length,
        streamCount: playing.reduce((sum, group) => sum + group.streamCount, 0) + recording.reduce((sum, group) => sum + group.streamCount, 0)
    };
}
