.pragma library
.import "WallpaperTimeRuleModel.js" as RuleModel
.import "../../core/LocalCalendar.js" as LocalCalendar

var minuteMs = 60000
var maximumLookaheadDays = 8
var maximumScannedMinutes = maximumLookaheadDays * 1440

function signature(result) {
    return String(result?.state || "unmatched") + "|"
        + String(result?.ruleId || "") + "|"
        + String(result?.playlistId || "")
}

function boundaryMinutes(rules) {
    const result = ({})
    for (const rule of rules || []) {
        if (!rule?.enabled)
            continue
        result[Math.max(0, Math.min(1439,
            Math.floor(Number(rule.startMinute) || 0)))] = true
        result[Math.max(0, Math.min(1439,
            Math.floor(Number(rule.endMinute) || 0)))] = true
    }
    return result
}

function none(current, scanned) {
    return {
        state: "none",
        nextAtMs: 0,
        minutesScanned: scanned || 0,
        current: current,
        next: null,
        local: null,
        reason: "no-boundary-in-lookahead"
    }
}

function nextBoundary(rules, screenName, nowMs, partsProvider) {
    const values = rules || []
    const provider = typeof partsProvider === "function"
        ? partsProvider : LocalCalendar.parts
    const now = Math.max(0, Math.floor(Number(nowMs) || Date.now()))
    const currentParts = LocalCalendar.normalizeParts(provider(now))
    const current = RuleModel.resolve(values, screenName,
        currentParts.day, currentParts.minute)
    const boundaries = boundaryMinutes(values)
    if (Object.keys(boundaries).length === 0)
        return none(current, 0)

    const firstMinute = Math.floor(now / minuteMs) * minuteMs + minuteMs
    let previous = currentParts
    for (let index = 0; index < maximumScannedMinutes; ++index) {
        const timestamp = firstMinute + index * minuteMs
        const parts = LocalCalendar.normalizeParts(provider(timestamp))
        const timezoneTransition =
            parts.timezoneOffset !== previous.timezoneOffset
        const candidate = boundaries[parts.minute] === true
            || parts.day !== previous.day
            || timezoneTransition
        previous = parts
        if (!candidate)
            continue
        const resolved = RuleModel.resolve(values, screenName,
            parts.day, parts.minute)
        if (signature(resolved) !== signature(current)) {
            return {
                state: "scheduled",
                nextAtMs: timestamp,
                minutesScanned: index + 1,
                current: current,
                next: resolved,
                local: parts,
                reason: timezoneTransition
                    ? "timezone-transition" : "rule-boundary"
            }
        }
    }
    return none(current, maximumScannedMinutes)
}
