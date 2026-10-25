function finite(value, fallback) {
    const number = Number(value)
    return Number.isFinite(number) ? number : Number(fallback)
}

function decimalsFor(stepSize) {
    const text = String(Math.abs(finite(stepSize, 1)))
    if (text.indexOf("e-") >= 0)
        return Math.min(6, Number(text.split("e-")[1]) || 0)
    const point = text.indexOf(".")
    return point < 0 ? 0 : Math.min(6, text.length - point - 1)
}

function clamp(value, minimum, maximum, fallback) {
    const low = finite(minimum, 0)
    const high = Math.max(low, finite(maximum, low))
    const number = finite(value, fallback)
    return Math.max(low, Math.min(high, number))
}

function quantize(value, minimum, maximum, stepSize, fallback) {
    const low = finite(minimum, 0)
    const step = Math.max(0, finite(stepSize, 0))
    let result = clamp(value, low, maximum, fallback)
    if (step > 0)
        result = low + Math.round((result - low) / step) * step
    return Number(clamp(result, low, maximum, fallback)
        .toFixed(decimalsFor(step)))
}

function stepped(value, direction, minimum, maximum, stepSize) {
    const step = Math.max(0, finite(stepSize, 0))
    return quantize(finite(value, minimum)
        + (direction < 0 ? -step : step), minimum, maximum, step, minimum)
}
