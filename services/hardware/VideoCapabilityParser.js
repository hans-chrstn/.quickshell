function codecForProfile(profile) {
    const value = String(profile || "").toLowerCase()
    if (value.indexOf("av1") >= 0) return "av1"
    if (value.indexOf("hevc") >= 0) return "hevc"
    if (value.indexOf("h264") >= 0) return "h264"
    if (value.indexOf("vp9") >= 0) return "vp9"
    return ""
}

function parseVainfo(text, renderNode) {
    const source = String(text || "")
    const codecs = []
    const seen = ({})
    let driver = ""
    for (const rawLine of source.split(/\r?\n/)) {
        const line = rawLine.trim()
        const driverMatch = line.match(/Driver version:\s*(.+)$/i)
        if (driverMatch)
            driver = driverMatch[1].trim()
        if (line.indexOf("VAEntrypointVLD") < 0)
            continue
        const profileMatch = line.match(/VAProfile[^\s:]*/)
        const codec = codecForProfile(profileMatch ? profileMatch[0] : "")
        if (codec.length === 0 || seen[codec])
            continue
        seen[codec] = true
        codecs.push(codec)
    }
    return {
        renderNode: String(renderNode || ""),
        driver: driver,
        decodeCodecs: codecs.sort()
    }
}

function mergedCodecs(records) {
    const result = []
    const seen = ({})
    for (const record of records || []) {
        for (const codec of record.decodeCodecs || []) {
            if (seen[codec]) continue
            seen[codec] = true
            result.push(codec)
        }
    }
    return result.sort()
}

function recommendedCodec(codecs) {
    const available = codecs || []
    for (const codec of ["av1", "hevc", "h264"])
        if (available.indexOf(codec) >= 0) return codec
    return "h264"
}

function parseEncoders(text) {
    const result = []
    const seen = ({})
    for (const rawLine of String(text || "").split(/\r?\n/)) {
        const match = rawLine.match(/^\s*V[^\s]*\s+(libx264|libx265|libsvtav1|libaom-av1|librav1e)\s/)
        if (!match || seen[match[1]]) continue
        seen[match[1]] = true
        result.push(match[1])
    }
    return result.sort()
}

function encoderForCodec(encoders, codec) {
    const available = encoders || []
    const preferences = codec === "av1"
        ? ["libsvtav1", "librav1e", "libaom-av1"]
        : codec === "hevc" ? ["libx265"]
        : codec === "h264" ? ["libx264"] : []
    for (const encoder of preferences)
        if (available.indexOf(encoder) >= 0) return encoder
    return ""
}

function codecCandidates(decodeCodecs, encoders) {
    const decoded = decodeCodecs || []
    const result = []
    for (const codec of ["h264", "hevc", "av1"]) {
        const encoder = encoderForCodec(encoders, codec)
        const decodeVerified = decoded.indexOf(codec) >= 0
        result.push({
            codec: codec,
            encoder: encoder,
            encoderAvailable: encoder.length > 0,
            decodeVerified: decodeVerified,
            benchmarkable: encoder.length > 0,
            eligible: encoder.length > 0
                && (decodeVerified || codec === "h264"),
            policy: codec === "h264" ? "conservative"
                : decodeVerified && encoder.length > 0
                    ? "measurement-required"
                    : encoder.length > 0
                        ? "runtime-proof-required" : "unavailable"
        })
    }
    return result
}
