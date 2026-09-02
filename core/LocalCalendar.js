.pragma library

function parts(timestampMs) {
    const date = new Date(timestampMs)
    return {
        day: date.getDay(),
        minute: date.getHours() * 60 + date.getMinutes(),
        timezoneOffset: date.getTimezoneOffset(),
        year: date.getFullYear(),
        month: date.getMonth() + 1,
        date: date.getDate()
    }
}

function normalizeParts(value) {
    const source = value || ({})
    const rawDay = Math.floor(Number(source.day) || 0)
    return {
        day: ((rawDay % 7) + 7) % 7,
        minute: Math.max(0, Math.min(1439,
            Math.floor(Number(source.minute) || 0))),
        timezoneOffset: Math.floor(Number(source.timezoneOffset) || 0),
        year: Math.floor(Number(source.year) || 0),
        month: Math.floor(Number(source.month) || 0),
        date: Math.floor(Number(source.date) || 0)
    }
}
