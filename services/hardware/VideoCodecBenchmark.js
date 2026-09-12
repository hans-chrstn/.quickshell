function outputExtension(codec) {
    return "mp4"
}

function encoderArguments(codec, encoder) {
    if (codec === "h264" && encoder === "libx264")
        return ["-c:v", encoder, "-preset", "veryfast", "-crf", "23",
            "-pix_fmt", "yuv420p"]
    if (codec === "hevc" && encoder === "libx265")
        return ["-c:v", encoder, "-preset", "fast", "-crf", "28",
            "-pix_fmt", "yuv420p", "-tag:v", "hvc1"]
    if (codec === "av1" && encoder === "libsvtav1")
        return ["-c:v", encoder, "-preset", "10", "-crf", "35",
            "-pix_fmt", "yuv420p"]
    if (codec === "av1" && encoder === "librav1e")
        return ["-c:v", encoder, "-speed", "10", "-qp", "100",
            "-pix_fmt", "yuv420p"]
    if (codec === "av1" && encoder === "libaom-av1")
        return ["-c:v", encoder, "-cpu-used", "8", "-crf", "35",
            "-b:v", "0", "-pix_fmt", "yuv420p"]
    return []
}

function runnableCandidates(candidates) {
    return (candidates || []).filter(candidate =>
        candidate && candidate.benchmarkable === true
            && encoderArguments(candidate.codec, candidate.encoder).length > 0)
}

function command(ffmpegPath, sourcePath, outputPath, candidate) {
    const encoder = encoderArguments(candidate.codec, candidate.encoder)
    if (encoder.length === 0)
        return []
    return [ffmpegPath, "-v", "error", "-y", "-t", "3", "-i",
        sourcePath, "-map", "0:v:0", "-an", "-sn", "-dn",
        "-map_metadata", "-1", "-map_chapters", "-1", "-vf",
        "scale='min(iw,1280)':'min(ih,720)':force_original_aspect_ratio=decrease,"
            + "pad=ceil(iw/2)*2:ceil(ih/2)*2,fps=24"
    ].concat(encoder, ["-movflags", "+faststart", outputPath])
}
