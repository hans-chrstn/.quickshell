function codecLabel(codec) {
    const value = String(codec || "").toLowerCase()
    if (value === "h264") return "H.264"
    if (value === "hevc") return "HEVC"
    if (value === "av1") return "AV1"
    return value.length > 0 ? value.toUpperCase() : "Unknown codec"
}

function numberLabel(value, decimals) {
    const number = Number(value)
    if (!Number.isFinite(number) || number <= 0)
        return ""
    return number.toFixed(decimals).replace(/\.0+$/, "")
}

function describe(recipe) {
    const value = recipe || ({})
    if (value.targetAvailable === false)
        return String(value.targetError || "Display geometry is unavailable")

    const parts = ["Original retained"]
    const width = Math.max(0, Number(value.outputWidth) || 0)
    const height = Math.max(0, Number(value.outputHeight) || 0)
    if (width > 0 && height > 0)
        parts.push(width + "×" + height)
    else
        parts.push("Native resolution")
    parts.push(codecLabel(value.codec))

    const frameRate = numberLabel(value.frameRate, 2)
    if (frameRate.length > 0)
        parts.push(frameRate + " FPS")
    const bitRate = numberLabel(value.bitRateMbps, 1)
    if (bitRate.length > 0)
        parts.push("≤" + bitRate + " Mbps")
    if (value.audioRemoved !== false)
        parts.push("Audio removed")
    return parts.join(" · ")
}
