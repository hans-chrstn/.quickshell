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

function routeNames(role, streams, records, links) {
    const streamIds = new Set(streams.map(stream => stream.id));
    const routeIds = new Set();
    for (const link of links || []) {
        const sourceId = Math.max(0, Math.trunc(Number(link?.sourceId) || 0));
        const targetId = Math.max(0, Math.trunc(Number(link?.targetId) || 0));
        if (role === "playback-stream" && streamIds.has(sourceId))
            routeIds.add(targetId);
        else if (role === "recording-stream" && streamIds.has(targetId))
            routeIds.add(sourceId);
    }

    const names = [];
    for (const record of records || []) {
        if (!routeIds.has(Math.max(0, Math.trunc(Number(record?.id) || 0))))
            continue;
        const name = bounded(record?.displayName || record?.name, 160);
        if (name.length > 0 && !names.includes(name))
            names.push(name);
    }
    return names.sort((left, right) => left.localeCompare(right));
}

function groupRecord(role, identity, applicationRecords, allRecords, links) {
    const section = roleSection(role);
    const streams = applicationRecords.map(compactStream).sort((left, right) => left.sessionId.localeCompare(right.sessionId) || left.id - right.id);
    const volumes = streams.map(stream => stream.volume).filter(value => Number.isFinite(value));
    const muteValues = streams.map(stream => stream.muted).filter(value => value !== null);
    const minimumVolume = volumes.length > 0 ? Math.min(...volumes) : null;
    const maximumVolume = volumes.length > 0 ? Math.max(...volumes) : null;
    const allMuted = muteValues.length === streams.length && muteValues.every(Boolean);
    const someMuted = muteValues.some(Boolean);
    const routes = routeNames(role, streams, allRecords, links);

    return {
        key: role + ":" + identity,
        applicationKey: identity.startsWith("unidentified:") ? "" : identity,
        identityKind: bounded(applicationRecords[0]?.applicationIdentityKind, 48) || "none",
        section: section,
        direction: section === "playing" ? "output" : "input",
        displayName: displayName(applicationRecords),
        iconName: iconName(applicationRecords),
        ready: streams.length > 0 && streams.every(stream => stream.ready),
        active: streams.length > 0,
        streamCount: streams.length,
        streamNodeIds: streams.map(stream => stream.id),
        streamSessionIds: streams.map(stream => stream.sessionId),
        volume: average(volumes),
        mixedVolume: volumes.length > 1 && maximumVolume - minimumVolume > 0.005,
        muted: allMuted,
        mixedMute: someMuted && !allMuted,
        routeNames: routes,
        routeCount: routes.length,
        routeSummary: routes.length === 0 ? "Route unavailable" : routes.length === 1 ? routes[0] : routes.length + " routes",
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

function groupedApplications(records, links) {
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
        const group = groupRecord(role, identity, buckets[key], records, links);
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

function applicationByKey(applications, groupKey) {
    const key = text(groupKey);
    if (key.length === 0)
        return null;
    const source = applications || ({});
    const playing = Array.isArray(source.playing) ? source.playing : [];
    const recording = Array.isArray(source.recording) ? source.recording : [];
    return playing.concat(recording).find(group => text(group?.key) === key) || null;
}

function applicationSelectionKey(rows, currentKey, command) {
    const keys = (rows || []).filter(row => row?.kind === "application").map(row => text(row.key)).filter(key => key.length > 0);
    if (keys.length === 0)
        return "";

    const currentIndex = keys.indexOf(text(currentKey));
    if (command === "first")
        return keys[0];
    if (command === "last")
        return keys[keys.length - 1];
    if (currentIndex < 0)
        return command === "previous" ? keys[keys.length - 1] : keys[0];
    if (command === "previous")
        return keys[Math.max(0, currentIndex - 1)];
    if (command === "next")
        return keys[Math.min(keys.length - 1, currentIndex + 1)];
    return keys[currentIndex];
}

function listRows(applications) {
    const source = applications || ({});
    const playing = Array.isArray(source.playing) ? source.playing : [];
    const recording = Array.isArray(source.recording) ? source.recording : [];
    const divided = playing.length > 0 && recording.length > 0;
    const rows = [];
    const append = (section, label, values) => {
        if (divided) {
            rows.push({
                kind: "section",
                key: "section:" + section,
                section: section,
                label: label,
                count: values.length
            });
        }
        for (const group of values)
            rows.push(Object.assign({
                kind: "application"
            }, group));
    };
    append("playing", "Playing", playing);
    append("recording", "Recording", recording);
    return rows;
}
