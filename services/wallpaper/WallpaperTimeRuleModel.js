.pragma library

var schemaVersion = 1
var maximumRules = 128
var minimumPriority = -1000
var maximumPriority = 1000

function identifier(value, fallback) {
    const cleaned = String(value || "").trim()
        .replace(/[^A-Za-z0-9._-]+/g, "-")
        .replace(/^-+|-+$/g, "")
    return (cleaned.length > 0 ? cleaned : fallback).slice(0, 96)
}

function minute(value) {
    const numeric = Math.floor(Number(value))
    if (!Number.isFinite(numeric))
        return 0
    return Math.max(0, Math.min(1439, numeric))
}

function days(values) {
    const result = []
    for (const value of values || []) {
        const day = Math.floor(Number(value))
        if (Number.isFinite(day) && day >= 0 && day <= 6
                && result.indexOf(day) < 0)
            result.push(day)
    }
    result.sort((first, second) => first - second)
    return result
}

function normalizeRules(values) {
    const result = []
    const used = ({})
    for (let index = 0; index < (values || []).length
            && result.length < maximumRules; ++index) {
        const source = values[index] || ({})
        const playlistId = String(source.playlistId || "")
            .trim().slice(0, 96)
        if (playlistId.length === 0)
            continue
        const base = identifier(source.id, "rule-" + (index + 1))
        let id = base
        let suffix = 2
        while (used[id]) {
            id = base + "-" + suffix
            ++suffix
        }
        used[id] = true
        result.push({
            id: id,
            name: String(source.name || "").trim().slice(0, 160)
                || "Untitled Rule",
            enabled: source.enabled !== false,
            playlistId: playlistId,
            screenName: String(source.screenName || "")
                .trim().slice(0, 128),
            days: days(source.days),
            startMinute: minute(source.startMinute),
            endMinute: minute(source.endMinute),
            priority: Math.max(minimumPriority, Math.min(maximumPriority,
                Math.floor(Number(source.priority) || 0)))
        })
    }
    return result
}

function normalizeDocument(value) {
    return {
        schemaVersion: schemaVersion,
        rules: normalizeRules(value?.rules)
    }
}

function includesDay(ruleDays, day) {
    return ruleDays.length === 0 || ruleDays.indexOf(day) >= 0
}

function active(rule, day, currentMinute) {
    if (!rule?.enabled)
        return false
    const normalizedDay = ((Math.floor(Number(day) || 0) % 7) + 7) % 7
    const now = minute(currentMinute)
    const start = minute(rule.startMinute)
    const end = minute(rule.endMinute)
    if (start === end)
        return includesDay(rule.days || [], normalizedDay)
    if (start < end)
        return includesDay(rule.days || [], normalizedDay)
            && now >= start && now < end
    if (now >= start)
        return includesDay(rule.days || [], normalizedDay)
    const previousDay = (normalizedDay + 6) % 7
    return now < end && includesDay(rule.days || [], previousDay)
}

function resolve(values, screenName, day, currentMinute) {
    const screen = String(screenName || "").trim().slice(0, 128)
    const candidates = []
    for (const rule of values || []) {
        const target = String(rule?.screenName || "")
        if ((target.length === 0 || target === screen)
                && active(rule, day, currentMinute))
            candidates.push(rule)
    }
    candidates.sort((first, second) => {
        const priority = Number(second.priority) - Number(first.priority)
        if (priority !== 0)
            return priority
        const firstSpecific = String(first.screenName || "").length > 0
        const secondSpecific = String(second.screenName || "").length > 0
        if (firstSpecific !== secondSpecific)
            return secondSpecific ? 1 : -1
        const firstId = String(first.id || "")
        const secondId = String(second.id || "")
        return firstId < secondId ? -1 : firstId > secondId ? 1 : 0
    })
    const winner = candidates[0]
    return winner ? {
        state: "matched",
        ruleId: String(winner.id || ""),
        playlistId: String(winner.playlistId || ""),
        screenName: screen,
        priority: Number(winner.priority) || 0,
        candidateCount: candidates.length
    } : {
        state: "unmatched",
        ruleId: "",
        playlistId: "",
        screenName: screen,
        priority: 0,
        candidateCount: 0
    }
}
