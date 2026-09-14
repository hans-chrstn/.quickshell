.pragma library

function finiteNumber(value, fallback) {
    const numeric = Number(value)
    return Number.isFinite(numeric) ? numeric : fallback
}

function values(source, count, fallback) {
    const input = Array.isArray(source) ? source : []
    const result = []
    for (let index = 0; index < count; ++index)
        result.push(Math.max(0, finiteNumber(input[index], fallback)))
    return result
}

function normalizedWeights(source, count) {
    const weights = values(source, count, 1)
    const sum = weights.reduce((total, value) => total + value, 0)
    if (sum <= 0) return weights.map(() => 1 / count)
    return weights.map(value => value / sum)
}

function resolve(totalLength, gap, minimums, extraWeights) {
    const count = Math.max(1, Array.isArray(minimums) ? minimums.length : 1)
    const spacing = Math.max(0, finiteNumber(gap, 0))
    const minimum = values(minimums, count, 0)
    const minimumContentLength = minimum.reduce((sum, value) => sum + value, 0)
    const minimumTotalLength = minimumContentLength + spacing * (count - 1)
    const requestedLength = Math.max(0, finiteNumber(totalLength, 0))
    const contentLength = Math.max(minimumContentLength,
        requestedLength - spacing * (count - 1))
    const distributable = Math.max(0, contentLength - minimumContentLength)
    const weights = normalizedWeights(extraWeights, count)
    const sizes = minimum.map((value, index) =>
        value + distributable * weights[index])
    return {
        sizes: sizes,
        minimums: minimum,
        extraWeights: weights,
        gap: spacing,
        requestedLength: requestedLength,
        contentLength: contentLength,
        totalLength: contentLength + spacing * (count - 1),
        minimumTotalLength: minimumTotalLength,
        overflow: requestedLength < minimumTotalLength
    }
}

function weightsForSizes(sizes, minimums) {
    const count = Math.max(1, Array.isArray(minimums) ? minimums.length : 1)
    const minimum = values(minimums, count, 0)
    const current = values(sizes, count, 0)
    const extras = current.map((value, index) =>
        Math.max(0, value - minimum[index]))
    return normalizedWeights(extras, count)
}

function drag(layout, dividerIndex, delta) {
    if (!layout || !Array.isArray(layout.sizes)
            || !Array.isArray(layout.minimums))
        return { accepted: false, error: "Split layout is invalid",
            layout: layout }
    const index = Math.round(finiteNumber(dividerIndex, -1))
    if (index < 0 || index >= layout.sizes.length - 1)
        return { accepted: false, error: "Split divider is invalid",
            layout: layout }
    const sizes = layout.sizes.slice()
    const pairLength = sizes[index] + sizes[index + 1]
    const minimumLeft = layout.minimums[index]
    const minimumRight = layout.minimums[index + 1]
    const requestedLeft = sizes[index] + finiteNumber(delta, 0)
    const left = Math.max(minimumLeft,
        Math.min(pairLength - minimumRight, requestedLeft))
    sizes[index] = left
    sizes[index + 1] = pairLength - left
    const updated = Object.assign({}, layout, {
        sizes: sizes,
        extraWeights: weightsForSizes(sizes, layout.minimums)
    })
    return { accepted: true, error: "", layout: updated }
}
