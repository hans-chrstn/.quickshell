function escapedPattern(value) {
    return String(value || "").replace(/[.*+?^${}()|[\]\\]/g, "\\$&")
}

function parseQtFfmpegLog(text, codec) {
    const source = String(text || "")
    const normalizedCodec = String(codec || "").toLowerCase()
    const candidatePattern = new RegExp(
        "Found potential codec \\\"" + escapedPattern(normalizedCodec)
            + "\\\" for hw", "i")
    const candidateFound = normalizedCodec.length > 0
        && candidatePattern.test(source)
    const deviceAccepted = /HW device is OK/i.test(source)
    const formatSelected = /Selected format\s+\d+\s+for hw\s+\d+/i.test(source)
    const sectionStart = candidateFound
        ? source.search(candidatePattern) : -1
    const section = sectionStart >= 0 ? source.slice(sectionStart) : source
    const backendMatch = section.match(
        /Checking HW context:\s*([a-z0-9_-]+)[\s\S]*?HW device is OK/i)
    const backend = backendMatch ? backendMatch[1].toLowerCase() : ""
    const verified = candidateFound && deviceAccepted && formatSelected
        && backend.length > 0

    return {
        codec: normalizedCodec,
        candidateFound: candidateFound,
        deviceAccepted: deviceAccepted,
        formatSelected: formatSelected,
        backend: backend,
        hardwareDecodeVerified: verified,
        error: verified ? "" : "Qt FFmpeg did not prove hardware decoding"
    }
}
