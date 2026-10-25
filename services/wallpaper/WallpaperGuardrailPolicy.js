var fourKPixels = 3840 * 2160
var eightKPixels = 7680 * 4320
var advisoryBitRate = 20000000
var highBitRate = 50000000

function assess(media, hardware) {
    const record = media || ({})
    const support = hardware || ({})
    const issues = []
    let severity = 0
    const pixels = Number(record.width) * Number(record.height)
    const frameRate = Number(record.frameRate) || 0
    const bitRate = Number(record.bitRate) || 0
    const codec = String(record.codec || "").toLowerCase()

    function add(level, message) {
        severity = Math.max(severity, level)
        issues.push(message)
    }

    if (String(record.state || "") === "ready"
            && String(record.kind || "") === "video") {
        if (pixels >= eightKPixels)
            add(2, "8K-class resolution can require substantial decode memory")
        else if (pixels >= fourKPixels)
            add(frameRate > 30 ? 2 : 1,
                "4K-class video increases decoder and memory-bandwidth demand")

        if (frameRate > 60)
            add(2, "Frame rate above 60 FPS creates unusually high continuous work")
        else if (frameRate > 30)
            add(1, "Frame rate above 30 FPS increases continuous decode work")

        if (bitRate >= highBitRate)
            add(2, "Bitrate above 50 Mbps increases decode and I/O demand")
        else if (bitRate >= advisoryBitRate)
            add(1, "Bitrate above 20 Mbps may increase decode and I/O demand")

        const demanding = pixels >= fourKPixels || frameRate > 30
            || bitRate >= advisoryBitRate
        const advancedCodec = codec === "hevc" || codec === "av1"
        if (support.pipelineAccepted !== true
                && support.decodeProfileVerified !== true
                && (advancedCodec || demanding))
            add(1, (codec.length > 0 ? codec.toUpperCase() : "Codec")
                + " hardware decoding is unverified on this device")
        else if (support.decodeProfileVerified === true
                && support.pipelineAccepted !== true)
            issues.push("Hardware decode profile found; full Qt rendering path is not yet verified")
    }

    return {
        severity: severity,
        issues: issues,
        hardwareState: support.pipelineAccepted === true ? "accepted"
            : support.decodeProfileVerified === true ? "decode-profile"
            : "unverified"
    }
}
