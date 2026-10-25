.pragma library

const AUDIO = 1;
const STREAM = 4;
const SOURCE = 8;
const SINK = 16;

function text(value) {
    return value === undefined || value === null ? "" : String(value);
}

function propertyText(properties, key) {
    return text(properties?.[key]).trim();
}

function propertyTrue(properties, key) {
    const value = propertyText(properties, key).toLowerCase();
    return value === "1" || value === "true" || value === "yes";
}

function hasFlag(type, flag) {
    return (Number(type) & flag) === flag;
}

function endsWithMonitor(name) {
    return text(name).toLowerCase().endsWith(".monitor");
}

function physicalNameFallback(name) {
    const normalized = text(name).toLowerCase();
    return normalized.startsWith("alsa_") || normalized.startsWith("bluez_");
}

function boundedIdentityText(value) {
    let normalized = text(value).trim();
    if (normalized.toLowerCase().endsWith(".desktop"))
        normalized = normalized.slice(0, -8);
    return normalized.slice(0, 160).toLowerCase();
}

function applicationIdentity(properties, fallbackName) {
    const appId = boundedIdentityText(propertyText(properties, "application.id"));
    if (appId.length > 0)
        return {
            key: "application-id:" + appId,
            kind: "application-id",
            value: appId
        };

    const binary = boundedIdentityText(propertyText(properties, "application.process.binary"));
    if (binary.length > 0)
        return {
            key: "binary:" + binary,
            kind: "binary",
            value: binary
        };

    const displayFallback = boundedIdentityText(propertyText(properties, "application.name") || fallbackName);
    return {
        key: displayFallback.length > 0 ? "display-fallback:" + displayFallback : "",
        kind: displayFallback.length > 0 ? "display-fallback" : "none",
        value: displayFallback
    };
}

function nodeStableKey(classified, properties, name, sessionId) {
    if (classified.stream)
        return sessionId;
    const persistentName = boundedIdentityText(propertyText(properties, "node.name") || name);
    return persistentName.length > 0 ? classified.role + ":" + persistentName : sessionId;
}

function virtualEvidence(properties, name) {
    const factory = propertyText(properties, "factory.name").toLowerCase();
    const nodeName = text(name).toLowerCase();
    return propertyTrue(properties, "node.virtual") || factory.includes("support.null-audio") || factory.includes("filter-chain") || nodeName.includes("easyeffects");
}

function classification(node) {
    const type = Number(node?.type || 0);
    const properties = node?.properties || ({});
    const name = text(node?.name);
    const mediaClass = propertyText(properties, "media.class");
    const normalizedMediaClass = mediaClass.toLowerCase();
    const mediaClassAudio = normalizedMediaClass.startsWith("audio/") || normalizedMediaClass.endsWith("/audio");
    const audio = hasFlag(type, AUDIO) || !!node?.hasAudio || mediaClassAudio;
    const stream = hasFlag(type, STREAM) || !!node?.isStream;
    const source = hasFlag(type, SOURCE) || normalizedMediaClass.startsWith("audio/source");
    const sink = hasFlag(type, SINK) || !!node?.isSink && !hasFlag(type, SOURCE) || normalizedMediaClass.startsWith("audio/sink");
    const deviceApi = propertyText(properties, "device.api");
    const monitor = audio && !stream && source && (propertyText(properties, "device.class").toLowerCase() === "monitor" || propertyTrue(properties, "monitor.channel-volumes") || endsWithMonitor(name));
    const virtual = audio && !stream && virtualEvidence(properties, name);
    const physicalByProperty = audio && !stream && deviceApi.length > 0;
    const physicalByName = audio && !stream && !physicalByProperty && physicalNameFallback(name);

    let role = "non-audio";
    let specialization = "none";
    let confidence = "type-flags";

    if (!audio) {
        specialization = "non-audio";
    } else if (stream && sink && source) {
        role = "specialized-stream";
        specialization = "duplex-stream";
    } else if (stream && sink) {
        role = "playback-stream";
        specialization = "application";
    } else if (stream && source) {
        role = "recording-stream";
        specialization = "application";
    } else if (monitor) {
        role = "specialized-node";
        specialization = "monitor-source";
        confidence = endsWithMonitor(name) ? "name-fallback" : "property-backed";
    } else if (virtual) {
        role = "specialized-node";
        specialization = sink && source ? "virtual-duplex" : sink ? "virtual-output" : source ? "virtual-input" : "virtual-audio";
        confidence = "property-backed";
    } else if (sink && source) {
        role = "specialized-node";
        specialization = physicalByProperty || physicalByName ? "physical-duplex" : "unclassified-duplex";
        confidence = physicalByProperty ? "property-backed" : physicalByName ? "name-fallback" : "type-flags";
    } else if (sink && (physicalByProperty || physicalByName)) {
        role = "output-device";
        specialization = "physical";
        confidence = physicalByProperty ? "property-backed" : "name-fallback";
    } else if (source && (physicalByProperty || physicalByName)) {
        role = "input-device";
        specialization = "physical";
        confidence = physicalByProperty ? "property-backed" : "name-fallback";
    } else {
        role = "specialized-node";
        specialization = "internal-audio";
    }

    return {
        role: role,
        specialization: specialization,
        confidence: confidence,
        audio: audio,
        stream: stream,
        sink: sink,
        source: source,
        mediaClass: mediaClass,
        deviceApi: deviceApi
    };
}

function normalize(node) {
    const classified = classification(node);
    const properties = node?.properties || ({});
    const description = text(node?.description).trim();
    const nickname = text(node?.nickname).trim();
    const name = text(node?.name).trim();
    const ready = !!node?.ready;
    const hasAudio = classified.audio && !!node?.hasAudio;
    const nodeId = Math.max(0, Math.trunc(Number(node?.id || 0)));
    const objectSerial = boundedIdentityText(propertyText(properties, "object.serial"));
    const sessionId = objectSerial.length > 0 ? "pipewire-serial:" + objectSerial : "pipewire-node:" + nodeId;
    const identity = classified.stream ? applicationIdentity(properties, description || nickname || name) : {
        key: "",
        kind: "none",
        value: ""
    };

    return {
        id: nodeId,
        objectSerial: objectSerial,
        sessionId: sessionId,
        stableKey: nodeStableKey(classified, properties, name, sessionId),
        role: classified.role,
        specialization: classified.specialization,
        classificationConfidence: classified.confidence,
        name: name,
        displayName: description || nickname || propertyText(properties, "application.name") || name || "Unknown audio node",
        ready: ready,
        isDefault: !!node?.isDefault,
        isPreferredDefault: !!node?.isPreferredDefault,
        mediaClass: classified.mediaClass,
        deviceApi: classified.deviceApi,
        applicationId: propertyText(properties, "application.id"),
        applicationName: propertyText(properties, "application.name"),
        applicationBinary: propertyText(properties, "application.process.binary"),
        applicationKey: identity.key,
        applicationIdentityKind: identity.kind,
        iconName: propertyText(properties, "application.icon-name"),
        volume: hasAudio && Number.isFinite(Number(node?.volume)) ? Number(node.volume) : null,
        muted: hasAudio ? !!node?.muted : null,
        channels: Array.isArray(node?.channels) ? node.channels.slice() : [],
        capabilities: {
            volumeRead: ready && hasAudio,
            volumeWrite: ready && hasAudio,
            muteRead: ready && hasAudio,
            muteWrite: ready && hasAudio,
            preferredDefaultWrite: ready && (classified.role === "output-device" || classified.role === "input-device" || classified.specialization.startsWith("virtual-")),
            routeRead: ready && classified.stream,
            routeWrite: false
        }
    };
}

function normalizedNodes(nodes) {
    const records = [];
    for (const node of nodes || []) {
        const record = normalize(node);
        if (record.role !== "non-audio")
            records.push(record);
    }
    records.sort((left, right) => left.id - right.id || left.role.localeCompare(right.role) || left.name.localeCompare(right.name));
    return records;
}

function reconciledNodes(previousRecords, nextRecords) {
    const buckets = ({});
    for (const record of nextRecords || []) {
        const key = text(record?.stableKey);
        if (!Array.isArray(buckets[key]))
            buckets[key] = [];
        buckets[key].push(record);
    }

    const reconciled = [];
    for (const previous of previousRecords || []) {
        const key = text(previous?.stableKey);
        if (Array.isArray(buckets[key]) && buckets[key].length > 0)
            reconciled.push(buckets[key].shift());
    }
    for (const record of nextRecords || []) {
        const key = text(record?.stableKey);
        if (!Array.isArray(buckets[key]) || buckets[key].length === 0)
            continue;
        if (buckets[key][0] === record) {
            reconciled.push(record);
            buckets[key].shift();
        }
    }
    return reconciled;
}

function roleCounts(records) {
    const counts = {
        outputDevices: 0,
        inputDevices: 0,
        playbackStreams: 0,
        recordingStreams: 0,
        specializedNodes: 0,
        specializedStreams: 0
    };
    for (const record of records || []) {
        if (record.role === "output-device")
            counts.outputDevices += 1;
        else if (record.role === "input-device")
            counts.inputDevices += 1;
        else if (record.role === "playback-stream")
            counts.playbackStreams += 1;
        else if (record.role === "recording-stream")
            counts.recordingStreams += 1;
        else if (record.role === "specialized-stream")
            counts.specializedStreams += 1;
        else if (record.role === "specialized-node")
            counts.specializedNodes += 1;
    }
    return counts;
}

function safeProbeVolume(currentVolume) {
    const current = Math.max(0, Math.min(1, Number(currentVolume)));
    const target = current >= 0.05 ? current - 0.05 : current + 0.05;
    return Math.round(Math.max(0, Math.min(1, target)) * 1000) / 1000;
}

function approximatelyEqual(left, right, tolerance) {
    const allowedDifference = Math.max(0, Number(tolerance || 0));
    return Math.abs(Number(left) - Number(right)) <= allowedDifference;
}
