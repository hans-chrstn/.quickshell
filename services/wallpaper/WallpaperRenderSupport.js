.pragma library

function rendererFor(media) {
    const kind = String(media?.kind || "")
    const codec = String(media?.codec || "").toLowerCase()
    if (kind === "static")
        return codec === "webp" ? "" : "static"
    if (kind === "video")
        return "video"
    if (kind !== "animatedImage")
        return ""
    if (codec === "gif")
        return "animated-image"
    if (codec === "apng")
        return "animated-media"
    return ""
}

function animatedBackendFor(media) {
    const renderer = rendererFor(media)
    if (renderer === "animated-image")
        return "image"
    if (renderer === "animated-media")
        return "media"
    return ""
}

function supported(media) {
    return rendererFor(media).length > 0
}
