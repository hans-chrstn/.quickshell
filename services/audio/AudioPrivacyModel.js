.pragma library

function text(value) {
    return value === undefined || value === null ? "" : String(value).trim();
}

function integer(value) {
    const numeric = Number(value);
    return Number.isInteger(numeric) && numeric > 0 ? numeric : 0;
}

function sourceKind(record) {
    if (!record)
        return "unknown";
    if (record.role === "input-device" || record.specialization === "physical-duplex")
        return "physical-microphone";
    if (record.specialization === "virtual-input" || record.specialization === "virtual-duplex")
        return "virtual-microphone";
    if (record.specialization === "monitor-source")
        return "monitor-capture";
    return "unknown";
}

function clientRecord(stream) {
    const applicationKey = text(stream?.applicationKey).slice(0, 192);
    const sessionId = text(stream?.sessionId || stream?.stableKey).slice(0, 192);
    const identified = applicationKey.length > 0;
    return {
        key: identified ? applicationKey : sessionId.length > 0 ? "unknown:" + sessionId : "unknown:node:" + integer(stream?.id),
        applicationKey: applicationKey,
        displayName: identified ? text(stream?.applicationName || stream?.displayName).slice(0, 160) || "Unknown application" : "Unknown application",
        iconName: identified ? text(stream?.iconName).slice(0, 192) : "",
        identified: identified
    };
}

function sourceRecord(record, kind) {
    return {
        id: integer(record?.id),
        stableKey: text(record?.stableKey).slice(0, 256),
        displayName: text(record?.displayName || record?.name).slice(0, 160) || "Unknown input",
        kind: kind,
        microphone: kind === "physical-microphone" || kind === "virtual-microphone"
    };
}

function linkedSourceIds(records, links) {
    const recordingIds = new Set((Array.isArray(records) ? records : []).filter(record => record?.role === "recording-stream" && record?.ready === true).map(record => integer(record?.id)).filter(id => id > 0));
    const result = new Set();
    for (const link of Array.isArray(links) ? links : []) {
        const sourceId = integer(link?.sourceId);
        const targetId = integer(link?.targetId);
        if (sourceId > 0 && recordingIds.has(targetId))
            result.add(sourceId);
    }
    return Array.from(result).sort((left, right) => left - right);
}

function snapshot(records, links, backendReady) {
    const normalized = Array.isArray(records) ? records : [];
    const byId = ({});
    const recordingById = ({});
    for (const record of normalized) {
        const id = integer(record?.id);
        if (id === 0)
            continue;
        byId[id] = record;
        if (record?.role === "recording-stream" && record?.ready === true)
            recordingById[id] = record;
    }

    const clientsByKey = ({});
    const sourcesByKey = ({});
    const paths = [];
    const seenPaths = new Set();
    for (const link of Array.isArray(links) ? links : []) {
        const sourceId = integer(link?.sourceId);
        const targetId = integer(link?.targetId);
        const stream = recordingById[targetId];
        if (sourceId === 0 || targetId === 0 || !stream)
            continue;
        const pathKey = sourceId + ":" + targetId;
        if (seenPaths.has(pathKey))
            continue;
        seenPaths.add(pathKey);
        const source = byId[sourceId] || null;
        const kind = sourceKind(source);
        const client = clientRecord(stream);
        const sourceValue = sourceRecord(source || {
            id: sourceId
        }, kind);
        clientsByKey[client.key] = client;
        const sourceKey = sourceValue.stableKey.length > 0 ? sourceValue.stableKey : "node:" + sourceId;
        sourcesByKey[sourceKey] = sourceValue;
        paths.push({
            sourceId: sourceId,
            streamId: targetId,
            clientKey: client.key,
            sourceKey: sourceKey,
            kind: kind,
            microphone: sourceValue.microphone
        });
    }

    const clients = Object.values(clientsByKey).sort((left, right) => left.displayName.localeCompare(right.displayName) || left.key.localeCompare(right.key));
    const sources = Object.values(sourcesByKey).sort((left, right) => left.displayName.localeCompare(right.displayName) || left.stableKey.localeCompare(right.stableKey));
    paths.sort((left, right) => left.streamId - right.streamId || left.sourceId - right.sourceId);
    const microphonePaths = paths.filter(path => path.microphone);
    const monitorPaths = paths.filter(path => path.kind === "monitor-capture");
    const unknownPaths = paths.filter(path => path.kind === "unknown");
    return {
        backendReady: backendReady === true,
        captureActive: paths.length > 0,
        microphoneActive: microphonePaths.length > 0,
        monitorCaptureActive: monitorPaths.length > 0,
        unknownCaptureActive: unknownPaths.length > 0,
        clientCount: clients.length,
        sourceCount: sources.length,
        pathCount: paths.length,
        clients: clients,
        sources: sources,
        paths: paths
    };
}
