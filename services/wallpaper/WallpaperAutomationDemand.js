.pragma library

function requested(ready, globalPlaylistId, screenPlaylistIds, rules) {
    if (!ready)
        return false
    if (String(globalPlaylistId || "").trim().length > 0)
        return true
    if (Object.keys(screenPlaylistIds || ({})).length > 0)
        return true
    return (rules || []).some(rule => Boolean(rule?.enabled))
}
