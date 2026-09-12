function finiteNonNegative(value, fallback) {
    const number = Number(value)
    return Number.isFinite(number) && number >= 0 ? number : fallback
}

function normalizeAxis(minimumValue, preferredValue, maximumValue,
                       fallbackValue) {
    const fallback = finiteNonNegative(fallbackValue, 0)
    const minimum = finiteNonNegative(minimumValue, 0)
    const preferred = Math.max(minimum,
        finiteNonNegative(preferredValue, fallback))
    const requestedMaximum = finiteNonNegative(maximumValue, 0)
    const maximum = requestedMaximum > 0
        ? Math.max(minimum, requestedMaximum) : preferred

    return {
        minimum: minimum,
        preferred: Math.min(preferred, maximum),
        maximum: maximum
    }
}

function resolve(policy, bounds, fallback, intrinsic) {
    const request = policy && typeof policy === "object" ? policy : ({})
    const limits = bounds && typeof bounds === "object" ? bounds : ({})
    const defaults = fallback && typeof fallback === "object"
        ? fallback : ({})
    const measured = intrinsic && typeof intrinsic === "object"
        ? intrinsic : ({})
    const source = request.source === "intrinsic" ? "intrinsic" : "declared"
    const measuredWidth = finiteNonNegative(measured.width, 0)
    const measuredHeight = finiteNonNegative(measured.height, 0)
    const width = normalizeAxis(request.minimumWidth,
        source === "intrinsic" && measuredWidth > 0
            ? measuredWidth : request.preferredWidth,
        request.maximumWidth, defaults.width)
    const height = normalizeAxis(request.minimumHeight,
        source === "intrinsic" && measuredHeight > 0
            ? measuredHeight : request.preferredHeight,
        request.maximumHeight, defaults.height)
    const availableWidth = finiteNonNegative(limits.availableWidth,
        width.maximum)
    const availableHeight = finiteNonNegative(limits.availableHeight,
        height.maximum)
    const resolvedWidth = Math.min(width.preferred, availableWidth)
    const resolvedHeight = Math.min(height.preferred, availableHeight)

    return {
        source: source,
        measurementReady: source !== "intrinsic"
            || (measuredWidth > 0 && measuredHeight > 0),
        requestedWidth: width.preferred,
        requestedHeight: height.preferred,
        resolvedWidth: resolvedWidth,
        resolvedHeight: resolvedHeight,
        minimumWidth: width.minimum,
        minimumHeight: height.minimum,
        maximumWidth: width.maximum,
        maximumHeight: height.maximum,
        widthConstrained: resolvedWidth < width.preferred,
        heightConstrained: resolvedHeight < height.preferred,
        widthBelowMinimum: resolvedWidth < width.minimum,
        heightBelowMinimum: resolvedHeight < height.minimum
    }
}
