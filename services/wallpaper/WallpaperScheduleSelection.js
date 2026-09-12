.pragma library
.import "WallpaperTimeRuleSchedule.js" as TimeRuleSchedule

function applicableRules(rules, screenName) {
    const screen = String(screenName || "").trim().slice(0, 128)
    return (rules || []).filter(rule => {
        const target = String(rule?.screenName || "")
        return target.length === 0 || target === screen
    })
}

function reuse(cached, screenName, fallbackPlaylistId, nowMs,
        previousAtMs, timezoneOffset) {
    const now = Math.max(0, Math.floor(Number(nowMs) || Date.now()))
    if (!cached || now < Number(previousAtMs)
            || (Number(cached.nextAtMs) > 0
                && now >= Number(cached.nextAtMs))
            || Number(cached.observedTimezoneOffset)
                !== Number(timezoneOffset))
        return null
    const matched = cached.current?.state === "matched"
    return {
        playlistId: matched ? cached.current.playlistId
            : String(fallbackPlaylistId || "").trim().slice(0, 96),
        source: matched ? "time-rule" : "target",
        ruleId: matched ? cached.current.ruleId : "",
        rulePlan: Object.assign({}, cached, { minutesScanned: 0,
            reason: "cached-boundary" })
    }
}

function select(rules, screenName, fallbackPlaylistId, nowMs,
        partsProvider) {
    const screen = String(screenName || "").trim().slice(0, 128)
    const rulePlan = TimeRuleSchedule.nextBoundary(
        applicableRules(rules, screen), screen, nowMs, partsProvider)
    const matched = rulePlan.current?.state === "matched"
    return {
        playlistId: matched ? rulePlan.current.playlistId
            : String(fallbackPlaylistId || "").trim().slice(0, 96),
        source: matched ? "time-rule" : "target",
        ruleId: matched ? rulePlan.current.ruleId : "",
        rulePlan: rulePlan
    }
}
