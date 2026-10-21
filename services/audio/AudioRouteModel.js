.pragma library

function integer(value) {
    const numeric = Number(value);
    return Number.isInteger(numeric) && numeric > 0 ? numeric : 0;
}

function text(value) {
    return value === undefined || value === null ? "" : String(value).trim();
}

function serial(record) {
    const direct = integer(record?.objectSerial);
    if (direct > 0)
        return direct;
    const sessionId = text(record?.sessionId);
    if (!sessionId.startsWith("pipewire-serial:"))
        return 0;
    return integer(sessionId.slice("pipewire-serial:".length));
}

function isOutputTarget(record) {
    return record?.role === "output-device" || record?.specialization === "virtual-output" || record?.specialization === "virtual-duplex";
}

function outputTargets(records) {
    return (records || []).filter(record => record?.ready && isOutputTarget(record) && serial(record) > 0).map(record => ({
                id: integer(record.id),
                stableKey: text(record.stableKey),
                displayName: text(record.displayName || record.name),
                objectSerial: serial(record),
                isDefault: record.isDefault === true,
                physical: record.role === "output-device",
                effect: record.specialization === "virtual-output" || record.specialization === "virtual-duplex"
            })).filter(record => record.id > 0 && record.stableKey.length > 0).sort((left, right) => Number(right.physical) - Number(left.physical) || left.displayName.localeCompare(right.displayName) || left.stableKey.localeCompare(right.stableKey));
}

function routeRows(targets, defaultOutput) {
    const defaultId = integer(defaultOutput?.id);
    const defaultName = text(defaultOutput?.name || defaultOutput?.displayName).slice(0, 160);
    const rows = [
        {
            key: "default",
            targetStableKey: "",
            targetId: defaultId,
            displayName: defaultName || "System Output",
            detail: "System default",
            available: defaultId > 0,
            physical: false,
            effect: false,
            isDefault: true
        }
    ];
    const seen = new Set();
    for (const target of targets || []) {
        const key = text(target?.stableKey).slice(0, 256);
        const id = integer(target?.id);
        if (key.length === 0 || id === 0 || id === defaultId || target?.isDefault === true || seen.has(key))
            continue;
        seen.add(key);
        rows.push({
            key: key,
            targetStableKey: key,
            targetId: id,
            displayName: text(target?.displayName).slice(0, 160) || "Audio output",
            detail: target?.effect ? "Effect output" : "Output device",
            available: true,
            physical: target?.physical === true,
            effect: target?.effect === true,
            isDefault: target?.isDefault === true
        });
    }
    return rows;
}

function observedRouteKey(application, rows, defaultOutputId) {
    const targetIds = Array.from(new Set((application?.routeTargetIds || []).map(integer).filter(id => id > 0)));
    if (targetIds.length !== 1)
        return "";
    const targetId = targetIds[0];
    if (targetId === integer(defaultOutputId))
        return "default";
    return text((rows || []).find(row => integer(row?.targetId) === targetId)?.key);
}

function routeSelectionKey(rows, currentKey, command) {
    const keys = (rows || []).filter(row => row?.available !== false).map(row => text(row?.key)).filter(key => key.length > 0);
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

function playbackStream(records, streamId) {
    const id = integer(streamId);
    return (records || []).find(record => integer(record?.id) === id && record?.role === "playback-stream" && record?.ready) || null;
}

function outputTarget(records, targetId) {
    const id = integer(targetId);
    return (records || []).find(record => integer(record?.id) === id && record?.ready && isOutputTarget(record) && serial(record) > 0) || null;
}

function targetIdsForStreams(streamIds, links) {
    const streams = new Set((streamIds || []).map(integer).filter(id => id > 0));
    const targets = new Set();
    for (const link of links || []) {
        const sourceId = integer(link?.sourceId);
        const targetId = integer(link?.targetId);
        if (streams.has(sourceId) && targetId > 0)
            targets.add(targetId);
    }
    return Array.from(targets).sort((left, right) => left - right);
}

function routeObservation(streamIds, records, links, defaultOutputId) {
    const targetIds = targetIdsForStreams(streamIds, links);
    const byId = ({});
    for (const record of records || [])
        byId[integer(record?.id)] = record;
    const names = targetIds.map(id => text(byId[id]?.displayName || byId[id]?.name)).filter(name => name.length > 0);
    const defaultId = integer(defaultOutputId);
    return {
        targetIds: targetIds,
        targetNames: names,
        routeCount: targetIds.length,
        linked: targetIds.length > 0,
        split: targetIds.length > 1,
        onDefaultOutput: targetIds.length === 1 && defaultId > 0 && targetIds[0] === defaultId
    };
}

function probePlan(records, streamId, targetId) {
    const stream = playbackStream(records, streamId);
    if (!stream)
        return {
            accepted: false,
            code: "stream-unavailable",
            message: "The playback stream is unavailable."
        };
    const target = outputTarget(records, targetId);
    if (!target)
        return {
            accepted: false,
            code: "target-unavailable",
            message: "The output target is unavailable."
        };
    return {
        accepted: true,
        code: "accepted",
        message: "",
        streamId: integer(stream.id),
        streamSessionId: text(stream.sessionId),
        targetId: integer(target.id),
        targetStableKey: text(target.stableKey),
        targetSerial: serial(target)
    };
}

function metadataPinned(output) {
    const value = text(output);
    return value.includes("key:'target.object'") || value.includes("key:'target.node'");
}

function routeGroup(applications, groupKey) {
    const key = text(groupKey).slice(0, 256);
    const playing = Array.isArray(applications?.playing) ? applications.playing : [];
    return playing.find(group => text(group?.key) === key) || null;
}

function applicationRoutePlan(applications, records, groupKey, targetStableKey, defaultOutputId) {
    const group = routeGroup(applications, groupKey);
    if (!group)
        return {
            accepted: false,
            code: "application-ended",
            message: "The playback application is no longer available."
        };
    if (!group.active || !group.ready || group.direction !== "output")
        return {
            accepted: false,
            code: "application-unavailable",
            message: "The application is not ready for output routing."
        };

    const streams = Array.isArray(group.streams) ? group.streams : [];
    const streamIds = [];
    const sessionIds = [];
    for (const stream of streams) {
        const id = integer(stream?.id);
        const sessionId = text(stream?.sessionId).slice(0, 256);
        if (!stream?.ready || id === 0 || sessionId.length === 0 || streamIds.includes(id) || sessionIds.includes(sessionId))
            return {
                accepted: false,
                code: "stream-set-invalid",
                message: "The application stream set is incomplete or ambiguous."
            };
        streamIds.push(id);
        sessionIds.push(sessionId);
    }
    if (streamIds.length === 0 || streamIds.length !== Number(group.streamCount))
        return {
            accepted: false,
            code: "stream-set-invalid",
            message: "The application stream set is incomplete or ambiguous."
        };

    const requestedKey = text(targetStableKey).slice(0, 256);
    const followDefault = requestedKey.length === 0;
    const target = followDefault ? null : outputTargets(records).find(record => record.stableKey === requestedKey) || null;
    if (!followDefault && !target)
        return {
            accepted: false,
            code: "target-unavailable",
            message: "The requested output target is unavailable."
        };
    const defaultId = integer(defaultOutputId);
    if (followDefault && defaultId === 0)
        return {
            accepted: false,
            code: "default-unavailable",
            message: "No effective default output is currently available."
        };

    return {
        accepted: true,
        code: "accepted",
        message: "",
        groupKey: text(group.key),
        applicationKey: text(group.applicationKey),
        streamIds: streamIds.sort((left, right) => left - right),
        sessionIds: sessionIds.sort(),
        followDefault: followDefault,
        targetId: target?.id || 0,
        targetStableKey: target?.stableKey || "",
        targetSerial: target?.objectSerial || 0,
        defaultOutputId: defaultId
    };
}

function sameValues(left, right) {
    const first = (left || []).map(value => text(value)).sort();
    const second = (right || []).map(value => text(value)).sort();
    return first.length === second.length && first.every((value, index) => value === second[index]);
}

function routeContinuity(plan, applications, records, defaultOutputId) {
    if (!plan?.accepted)
        return {
            accepted: false,
            code: "invalid-plan",
            message: "The route request is invalid."
        };
    const group = routeGroup(applications, plan.groupKey);
    if (!group)
        return {
            accepted: false,
            code: "application-ended",
            message: "The playback application ended during routing."
        };
    const streamIds = (group.streams || []).map(stream => integer(stream?.id)).filter(id => id > 0);
    const sessionIds = (group.streams || []).map(stream => text(stream?.sessionId)).filter(value => value.length > 0);
    if (!group.active || !group.ready || group.direction !== "output" || !sameValues(streamIds, plan.streamIds) || !sameValues(sessionIds, plan.sessionIds))
        return {
            accepted: false,
            code: "stream-set-changed",
            message: "The application's playback streams changed during routing."
        };
    if (plan.followDefault && integer(defaultOutputId) === 0)
        return {
            accepted: false,
            code: "default-unavailable",
            message: "The system default output became unavailable during routing."
        };
    if (!plan.followDefault) {
        const target = outputTargets(records).find(record => record.stableKey === plan.targetStableKey && record.id === plan.targetId && record.objectSerial === plan.targetSerial);
        if (!target)
            return {
                accepted: false,
                code: "target-changed",
                message: "The requested output target changed during routing."
            };
    }
    return {
        accepted: true,
        code: "current",
        message: ""
    };
}

function routesMatch(plan, records, links, defaultOutputId) {
    if (!plan?.accepted)
        return false;
    const expectedId = plan.followDefault ? integer(defaultOutputId) : integer(plan.targetId);
    if (expectedId === 0)
        return false;
    return plan.streamIds.every(streamId => {
        const observation = routeObservation([streamId], records, links, defaultOutputId);
        return observation.targetIds.length === 1 && observation.targetIds[0] === expectedId;
    });
}

function metadataState(output) {
    const state = {
        targetObject: null,
        targetNode: null
    };
    const pattern = /key:'(target\.object|target\.node)' value:'([^']*)' type:'([^']*)'/g;
    let match = pattern.exec(text(output));
    while (match) {
        const record = {
            value: text(match[2]).slice(0, 512),
            type: text(match[3]).slice(0, 64)
        };
        if (match[1] === "target.object")
            state.targetObject = record;
        else
            state.targetNode = record;
        match = pattern.exec(text(output));
    }
    return state;
}

function metadataMatches(state, plan) {
    if (!plan?.accepted)
        return false;
    if (state?.targetNode !== null)
        return false;
    if (plan.followDefault)
        return state?.targetObject === null;
    return state?.targetObject?.value === String(plan.targetSerial) && state?.targetObject?.type === "Spa:Id";
}

function metadataEqual(left, right) {
    const equalRecord = (first, second) => first === null && second === null || first !== null && second !== null && first.value === second.value && first.type === second.type;
    return equalRecord(left?.targetObject ?? null, right?.targetObject ?? null) && equalRecord(left?.targetNode ?? null, right?.targetNode ?? null);
}

function queryCommands(streamIds) {
    return (streamIds || []).map(streamId => ({
                kind: "query",
                streamId: integer(streamId),
                command: ["pw-metadata", "-n", "default", String(integer(streamId))]
            }));
}

function propertyCommand(streamId, key, record) {
    const id = String(integer(streamId));
    if (record === null)
        return ["pw-metadata", "-n", "default", "-d", id, key];
    return ["pw-metadata", "-n", "default", id, key, text(record.value), text(record.type)];
}

function mutationCommands(plan) {
    const commands = [];
    for (const streamId of plan?.streamIds || []) {
        commands.push({
            kind: "mutation",
            streamId: integer(streamId),
            command: propertyCommand(streamId, "target.object", plan.followDefault ? null : {
                value: String(plan.targetSerial),
                type: "Spa:Id"
            })
        });
        commands.push({
            kind: "mutation",
            streamId: integer(streamId),
            command: propertyCommand(streamId, "target.node", null)
        });
    }
    return commands;
}

function rollbackCommands(streamIds, originals) {
    const commands = [];
    for (const streamId of streamIds || []) {
        const original = originals?.[String(integer(streamId))] || {
            targetObject: null,
            targetNode: null
        };
        commands.push({
            kind: "rollback",
            streamId: integer(streamId),
            command: propertyCommand(streamId, "target.object", original.targetObject)
        });
        commands.push({
            kind: "rollback",
            streamId: integer(streamId),
            command: propertyCommand(streamId, "target.node", original.targetNode)
        });
    }
    return commands;
}
