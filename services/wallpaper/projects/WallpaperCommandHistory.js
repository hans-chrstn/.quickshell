.pragma library

function finite(value, fallback) {
    const result = Number(value)
    return Number.isFinite(result) ? result : fallback
}

function normalize(value) {
    const source = value || ({})
    const maximum = Math.max(1, Math.round(finite(source.maximum, 100)))
    return {
        maximum: maximum,
        past: Array.isArray(source.past) ? source.past.slice(-maximum) : [],
        future: Array.isArray(source.future) ? source.future.slice(0, maximum) : []
    }
}

function empty(maximum) {
    return normalize({ maximum: maximum, past: [], future: [] })
}

function push(value, command) {
    const current = normalize(value)
    const entry = command || ({})
    if (!entry.before || !entry.after)
        return current
    const past = current.past.concat([entry]).slice(-current.maximum)
    return { maximum: current.maximum, past: past, future: [] }
}

function undo(value) {
    const current = normalize(value)
    if (current.past.length === 0)
        return { state: current, command: null }
    const past = current.past.slice()
    const command = past.pop()
    return {
        state: { maximum: current.maximum, past: past,
            future: [command].concat(current.future).slice(0, current.maximum) },
        command: command
    }
}

function redo(value) {
    const current = normalize(value)
    if (current.future.length === 0)
        return { state: current, command: null }
    const future = current.future.slice()
    const command = future.shift()
    return {
        state: { maximum: current.maximum,
            past: current.past.concat([command]).slice(-current.maximum),
            future: future },
        command: command
    }
}

