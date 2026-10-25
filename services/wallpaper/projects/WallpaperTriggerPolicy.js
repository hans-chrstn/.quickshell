.pragma library

var defaultCooldownMs = 1000;

function ordered(markers) {
    return (Array.isArray(markers) ? markers : []).slice().sort((left, right) => {
        const leftEnabled = left?.enabled === false ? 1 : 0;
        const rightEnabled = right?.enabled === false ? 1 : 0;
        if (leftEnabled !== rightEnabled)
            return leftEnabled - rightEnabled;
        const leftPriority = Number(left?.priority) || 0;
        const rightPriority = Number(right?.priority) || 0;
        if (leftPriority !== rightPriority)
            return rightPriority - leftPriority;
        const leftTime = Number(left?.timeMs) || 0;
        const rightTime = Number(right?.timeMs) || 0;
        if (leftTime !== rightTime)
            return leftTime - rightTime;
        return String(left?.id || "").localeCompare(String(right?.id || ""));
    });
}

function eligible(marker, nowMs, lastFiredMs, cooldownMs) {
    if (!marker || marker.enabled === false)
        return false;
    const now = Number(nowMs);
    const neverFired = lastFiredMs === undefined || lastFiredMs === null;
    const last = Number(lastFiredMs);
    const configuredCooldown = cooldownMs === undefined ? marker.cooldownMs : cooldownMs;
    const cooldown = Math.max(0, Number(configuredCooldown ?? defaultCooldownMs) || 0);
    if (!Number.isFinite(now) || (!neverFired && !Number.isFinite(last)))
        return false;
    if (neverFired)
        return true;
    return now >= last + cooldown;
}

function candidates(markers, nowMs, lastFiredById) {
    const fired = lastFiredById || ({});
    const eligibleMarkers = (Array.isArray(markers) ? markers : []).filter(marker => eligible(marker, nowMs, fired[marker?.id]));
    const sorted = ordered(eligibleMarkers);
    const exclusive = sorted.find(marker => marker.exclusive === true);
    return exclusive ? [exclusive] : sorted;
}

function eventDecision(marker, eventTimeMs, nowMs, lastFiredMs) {
    if (!marker || marker.enabled === false)
        return {
            accepted: false,
            reason: "disabled"
        };
    const eventTime = Number(eventTimeMs);
    const now = Number(nowMs);
    if (!Number.isFinite(eventTime) || !Number.isFinite(now))
        return {
            accepted: false,
            reason: "invalid-time"
        };
    if (eventTime > now)
        return {
            accepted: false,
            reason: "not-due"
        };
    if (!eligible(marker, now, lastFiredMs))
        return {
            accepted: false,
            reason: "cooldown"
        };
    if (eventTime < now && marker.missedEvent !== "fire-on-resume")
        return {
            accepted: false,
            reason: "missed"
        };
    return {
        accepted: true,
        reason: eventTime < now ? "missed-replay" : "due"
    };
}

function canLoop(marker, firedCount) {
    if (!marker || marker.enabled === false)
        return false;
    return marker.loopPolicy === "repeat" || Number(firedCount) <= 0;
}

function decisionTrace(markers, nowMs, lastFiredById) {
    const fired = lastFiredById || ({});
    return ordered(markers).map(marker => {
        const decision = eventDecision(marker, marker?.timeMs, nowMs, fired[marker?.id]);
        return {
            id: String(marker?.id || ""),
            triggerType: String(marker?.triggerType || "manual"),
            priority: Number(marker?.priority) || 0,
            accepted: decision.accepted,
            reason: decision.reason
        };
    });
}

function nextTimelineEvent(markers, playheadMs, durationMs, loop) {
    const playhead = Math.max(0, Number(playheadMs) || 0);
    const duration = Math.max(playhead, Number(durationMs) || 0);
    const enabled = (Array.isArray(markers) ? markers : []).filter(marker => marker?.enabled !== false).slice().sort((left, right) => {
        const leftTime = Number(left?.timeMs) || 0;
        const rightTime = Number(right?.timeMs) || 0;
        if (leftTime !== rightTime)
            return leftTime - rightTime;
        const leftPriority = Number(left?.priority) || 0;
        const rightPriority = Number(right?.priority) || 0;
        if (leftPriority !== rightPriority)
            return rightPriority - leftPriority;
        return String(left?.id || "").localeCompare(String(right?.id || ""));
    });
    const upcoming = enabled.find(marker => Number(marker.timeMs) >= playhead);
    if (upcoming)
        return {
            marker: upcoming,
            wrapped: false
        };
    if (loop === true && enabled.length > 0)
        return {
            marker: enabled[0],
            wrapped: true
        };
    return {
        marker: null,
        wrapped: false,
        ended: playhead >= duration
    };
}
