.pragma library

const MAX_POLICIES = 128;

function text(value) {
    return value === undefined || value === null ? "" : String(value).trim().toLowerCase();
}

function integer(value) {
    const numeric = Number(value);
    return Number.isInteger(numeric) && numeric > 0 ? numeric : 0;
}

function applicationIdentity(value) {
    const key = text(value).slice(0, 192);
    return key.startsWith("application-id:") && key.length > "application-id:".length || key.startsWith("binary:") && key.length > "binary:".length ? key : "";
}

function targetIdentity(value) {
    const key = text(value).slice(0, 256);
    return key.startsWith("output-device:") && key.length > "output-device:".length || key.startsWith("specialized-node:") && key.length > "specialized-node:".length ? key : "";
}

function normalizedPolicies(values) {
    const result = ({});
    if (!values || typeof values !== "object" || Array.isArray(values))
        return result;
    const keys = Object.keys(values).sort();
    let count = 0;
    for (const rawKey of keys) {
        if (count >= MAX_POLICIES)
            break;
        const applicationKey = applicationIdentity(rawKey);
        const targetStableKey = targetIdentity(values[rawKey]?.targetStableKey);
        if (applicationKey.length === 0 || targetStableKey.length === 0 || result[applicationKey])
            continue;
        result[applicationKey] = {
            targetStableKey: targetStableKey
        };
        count += 1;
    }
    return result;
}

function policyFor(values, applicationKey) {
    const key = applicationIdentity(applicationKey);
    const policies = normalizedPolicies(values);
    return key.length > 0 && policies[key] ? {
        applicationKey: key,
        targetStableKey: policies[key].targetStableKey
    } : null;
}

function update(values, applicationKey, targetStableKey) {
    const key = applicationIdentity(applicationKey);
    if (key.length === 0)
        return {
            accepted: false,
            code: "application-identity-unstable",
            message: "This application does not expose a stable identity for remembered routing.",
            policies: normalizedPolicies(values)
        };
    const policies = normalizedPolicies(values);
    const requestedTarget = text(targetStableKey);
    if (requestedTarget.length === 0) {
        if (policies[key])
            delete policies[key];
        return {
            accepted: true,
            code: "cleared",
            message: "",
            policies: policies
        };
    }
    const target = targetIdentity(requestedTarget);
    if (target.length === 0)
        return {
            accepted: false,
            code: "target-identity-unstable",
            message: "This output does not expose a stable identity for remembered routing.",
            policies: policies
        };
    if (!policies[key] && Object.keys(policies).length >= MAX_POLICIES)
        return {
            accepted: false,
            code: "policy-limit",
            message: "The remembered application route limit has been reached.",
            policies: policies
        };
    policies[key] = {
        targetStableKey: target
    };
    return {
        accepted: true,
        code: "stored",
        message: "",
        policies: policies
    };
}

function clear(values) {
    return {
        accepted: true,
        code: "cleared-all",
        message: "",
        removedCount: Object.keys(normalizedPolicies(values)).length,
        policies: ({})
    };
}

function reconciliationPlans(values, applications, targets, defaultOutputId) {
    const policies = normalizedPolicies(values);
    const groups = Array.isArray(applications?.playing) ? applications.playing : [];
    const outputs = Array.isArray(targets) ? targets : [];
    const defaultId = integer(defaultOutputId);
    const plans = [];
    for (const applicationKey of Object.keys(policies).sort()) {
        const targetStableKey = policies[applicationKey].targetStableKey;
        const group = groups.find(candidate => text(candidate?.applicationKey) === applicationKey && candidate?.active && candidate?.ready && candidate?.direction === "output") || null;
        const target = outputs.find(candidate => text(candidate?.stableKey) === targetStableKey && integer(candidate?.id) > 0 && integer(candidate?.objectSerial) > 0) || null;
        if (!group) {
            plans.push({
                applicationKey: applicationKey,
                groupKey: "",
                targetStableKey: targetStableKey,
                action: "none",
                state: "application-absent",
                signature: ""
            });
            continue;
        }
        const sessionIds = Array.from(new Set((group.streamSessionIds || []).map(text).filter(value => value.length > 0))).sort();
        const observedIds = Array.from(new Set((group.routeTargetIds || []).map(integer).filter(value => value > 0))).sort((left, right) => left - right);
        if (!target) {
            const fallback = defaultId > 0 && observedIds.length === 0;
            plans.push({
                applicationKey: applicationKey,
                groupKey: text(group.key),
                targetStableKey: targetStableKey,
                action: fallback ? "fallback" : "none",
                state: fallback ? "fallback-required" : "target-unavailable",
                signature: JSON.stringify([applicationKey, sessionIds, targetStableKey, "fallback", defaultId, observedIds])
            });
            continue;
        }
        const targetId = integer(target.id);
        const current = observedIds.length === 1 && observedIds[0] === targetId;
        plans.push({
            applicationKey: applicationKey,
            groupKey: text(group.key),
            targetStableKey: targetStableKey,
            action: current ? "none" : "apply",
            state: current ? "current" : "apply-required",
            signature: JSON.stringify([applicationKey, sessionIds, targetStableKey, targetId, integer(target.objectSerial), observedIds])
        });
    }
    return plans;
}
