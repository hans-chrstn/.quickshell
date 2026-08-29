.pragma library

function clippedRectangle(client, screen) {
    const at = client?.at
    const size = client?.size
    if (!at || at.length < 2 || !size || size.length < 2)
        return null
    const screenX = Number(screen.x) || 0
    const screenY = Number(screen.y) || 0
    const left = Math.max(screenX, Number(at[0]) || 0)
    const top = Math.max(screenY, Number(at[1]) || 0)
    const right = Math.min(screenX + Number(screen.width),
        (Number(at[0]) || 0) + (Number(size[0]) || 0))
    const bottom = Math.min(screenY + Number(screen.height),
        (Number(at[1]) || 0) + (Number(size[1]) || 0))
    return right > left && bottom > top
        ? { x1: left, y1: top, x2: right, y2: bottom } : null
}

function unionArea(rectangles) {
    let xs = []
    for (const rectangle of rectangles)
        xs.push(rectangle.x1, rectangle.x2)
    xs.sort((a, b) => a - b)
    xs = xs.filter((value, index) => index === 0 || value !== xs[index - 1])

    let area = 0
    for (let i = 0; i + 1 < xs.length; ++i) {
        const x1 = xs[i]
        const x2 = xs[i + 1]
        const intervals = []
        for (const rectangle of rectangles) {
            if (rectangle.x1 < x2 && rectangle.x2 > x1)
                intervals.push([rectangle.y1, rectangle.y2])
        }
        intervals.sort((a, b) => a[0] - b[0])

        let coveredY = 0
        let start = 0
        let end = 0
        for (let j = 0; j < intervals.length; ++j) {
            if (j === 0 || intervals[j][0] > end) {
                if (j > 0)
                    coveredY += end - start
                start = intervals[j][0]
                end = intervals[j][1]
            } else {
                end = Math.max(end, intervals[j][1])
            }
        }
        if (intervals.length > 0)
            coveredY += end - start
        area += (x2 - x1) * coveredY
    }
    return area
}
