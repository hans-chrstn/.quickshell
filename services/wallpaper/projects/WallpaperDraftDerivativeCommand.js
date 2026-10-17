.pragma library

.import "WallpaperDraftDerivativePlan.js" as Plan

function create(ffmpegPath, plan) {
    const executable = String(ffmpegPath || "")
    const item = plan || ({})
    if (!executable.startsWith("/") || !String(item.sourcePath || "").startsWith("/")
            || !String(item.temporaryPath || "").startsWith("/"))
        return []
    if (item.role === "thumbnail" && item.recipe === Plan.thumbnailRecipe)
        return [executable, "-v", "error", "-nostdin", "-n",
            "-threads", "1", "-filter_threads", "1",
            "-i", item.sourcePath, "-frames:v", "1", "-an", "-sn", "-dn",
            "-vf", "scale=480:270:force_original_aspect_ratio=increase,crop=480:270",
            item.temporaryPath]
    if (item.role === "proxy" && item.recipe === Plan.proxyRecipe)
        return [executable, "-v", "error", "-nostdin", "-n",
            "-threads", "1", "-filter_threads", "1",
            "-i", item.sourcePath, "-map", "0:v:0", "-an", "-sn", "-dn",
            "-vf", "scale=w='min(1280,iw)':h='min(720,ih)'"
                + ":force_original_aspect_ratio=decrease:force_divisible_by=2,fps=24",
            "-c:v", "libx264", "-preset", "veryfast", "-crf", "25",
            "-pix_fmt", "yuv420p", "-movflags", "+faststart",
            item.temporaryPath]
    return []
}

function timeoutFor(role) {
    return role === "thumbnail" ? 30000
        : role === "proxy" ? 600000 : 0
}
