.pragma library

function hashString(value) {
    const text = String(value || "")
    let hash = 2166136261
    for (let index = 0; index < text.length; ++index) {
        hash ^= text.charCodeAt(index)
        hash = Math.imul(hash, 16777619)
    }
    return hash >>> 0
}

function nextState(value) {
    let state = value >>> 0
    state ^= state << 13
    state ^= state >>> 17
    state ^= state << 5
    return state >>> 0
}

function shuffled(entries, seed, namespace) {
    const result = (entries || []).map(entry => Object.assign({}, entry))
    let state = (Number(seed) >>> 0) ^ hashString(namespace)
    if (state === 0)
        state = 0x6d2b79f5
    for (let index = result.length - 1; index > 0; --index) {
        state = nextState(state)
        const target = Math.floor((state / 4294967296) * (index + 1))
        const temporary = result[index]
        result[index] = result[target]
        result[target] = temporary
    }
    return result
}

function resolvedEntries(playlist) {
    const source = playlist || ({})
    const entries = source.entries || []
    if (source.mode !== "shuffle")
        return entries.map(entry => Object.assign({}, entry))
    return shuffled(entries, source.seed, source.id)
}
