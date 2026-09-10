.pragma library

var maximumDepth = 24

function value(source, depth) {
    const currentDepth = Number(depth) || 0
    if (source === null || source === undefined
            || typeof source !== "object")
        return source
    if (currentDepth >= maximumDepth)
        return null
    if (Array.isArray(source))
        return source.map(item => value(item, currentDepth + 1))
    const result = ({})
    for (const key in source)
        result[key] = value(source[key], currentDepth + 1)
    return result
}
