.pragma library

var maximumQueueLength = 8
var maximumTitleLength = 80
var maximumMessageLength = 360
var minimumDurationMs = 1800
var maximumDurationMs = 12000

function boundedText(value, maximum) {
    return String(value ?? "").replace(/[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]/g, "")
        .replace(/\s*\n+\s*/g, " ").trim().slice(0, maximum)
}

function severity(value) {
    const candidate = String(value || "").toLowerCase()
    return ["info", "success", "warning", "error"].indexOf(candidate) >= 0
        ? candidate : "info"
}

function defaultDuration(level) {
    if (level === "error") return 7000
    if (level === "warning") return 6000
    return 4200
}

function normalize(input, nowMs, sequence) {
    const source = input || ({})
    const level = severity(source.severity)
    const title = boundedText(source.title, maximumTitleLength)
    const message = boundedText(source.message, maximumMessageLength)
    if (title.length === 0 && message.length === 0)
        return null
    const requestedDuration = Number(source.durationMs)
    const duration = Number.isFinite(requestedDuration) && requestedDuration > 0
        ? requestedDuration : defaultDuration(level)
    return {
        id: "notice-" + Math.max(0, Number(nowMs) || 0).toString(36)
            + "-" + Math.max(1, Number(sequence) || 1).toString(36),
        severity: level,
        title: title.length > 0 ? title
            : level === "error" ? "Something went wrong"
            : level === "warning" ? "Attention" : "Notice",
        message: message,
        source: boundedText(source.source, 64),
        screenName: boundedText(source.screenName, 128),
        dedupeKey: boundedText(source.dedupeKey, 128),
        durationMs: Math.max(minimumDurationMs,
            Math.min(maximumDurationMs, Math.round(duration))),
        createdAtMs: Math.max(0, Number(nowMs) || 0),
        occurrenceCount: 1
    }
}

function sameNotice(left, right) {
    if (!left || !right) return false
    if (right.dedupeKey.length > 0)
        return left.dedupeKey === right.dedupeKey
            && left.source === right.source
            && left.screenName === right.screenName
    return left.severity === right.severity
        && left.title === right.title
        && left.message === right.message
        && left.source === right.source
        && left.screenName === right.screenName
}

function enqueue(queue, input, nowMs, sequence) {
    const notice = normalize(input, nowMs, sequence)
    const current = Array.isArray(queue) ? queue.slice(0, maximumQueueLength) : []
    if (!notice) return { accepted: false, queue: current, notice: null,
        deduplicated: false }
    const duplicateIndex = current.findIndex(item => sameNotice(item, notice))
    if (duplicateIndex >= 0) {
        const previous = current[duplicateIndex]
        notice.id = previous.id
        notice.createdAtMs = previous.createdAtMs
        notice.occurrenceCount = Math.min(999,
            (Number(previous.occurrenceCount) || 1) + 1)
        current[duplicateIndex] = notice
        return { accepted: true, queue: current, notice: notice,
            deduplicated: true }
    }
    if (current.length >= maximumQueueLength)
        current.splice(current.length > 1 ? 1 : 0, 1)
    current.push(notice)
    return { accepted: true, queue: current, notice: notice,
        deduplicated: false }
}
