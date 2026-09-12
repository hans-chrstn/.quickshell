function recipe(candidate) {
    const codec = String(candidate?.codec || "").toLowerCase()
    const encoder = String(candidate?.encoder || "")

    if (codec === "hevc" && encoder === "libx265")
        return {
            codec: codec,
            encoder: encoder,
            version: "hevc-crf28-clean-v1",
            arguments: ["-c:v", encoder, "-preset", "medium", "-crf", "28",
                "-pix_fmt", "yuv420p", "-tag:v", "hvc1"]
        }
    if (codec === "av1" && encoder === "libsvtav1")
        return {
            codec: codec,
            encoder: encoder,
            version: "av1-svt-crf32-clean-v1",
            arguments: ["-c:v", encoder, "-preset", "8", "-crf", "32",
                "-pix_fmt", "yuv420p"]
        }
    if (codec === "av1" && encoder === "librav1e")
        return {
            codec: codec,
            encoder: encoder,
            version: "av1-rav1e-qp90-clean-v1",
            arguments: ["-c:v", encoder, "-speed", "8", "-qp", "90",
                "-pix_fmt", "yuv420p"]
        }
    if (codec === "av1" && encoder === "libaom-av1")
        return {
            codec: codec,
            encoder: encoder,
            version: "av1-aom-crf32-clean-v1",
            arguments: ["-c:v", encoder, "-cpu-used", "6", "-crf", "32",
                "-b:v", "0", "-pix_fmt", "yuv420p"]
        }
    return {
        codec: "h264",
        encoder: "libx264",
        version: "h264-crf23-clean-v3",
        arguments: ["-c:v", "libx264", "-preset", "medium", "-crf", "23",
            "-pix_fmt", "yuv420p"]
    }
}
