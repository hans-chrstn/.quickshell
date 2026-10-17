function physicalDimensions(screens, target) {
    const targetName = String(target || "").trim()
    if (targetName.length === 0)
        return { available: false, width: 0, height: 0, matches: 0,
            error: "A wallpaper target is required" }

    let width = 0
    let height = 0
    let matches = 0
    for (const screen of screens || []) {
        if (targetName !== "All Displays"
                && String(screen?.name || "") !== targetName)
            continue
        const logicalWidth = Math.max(0, Number(screen?.width) || 0)
        const logicalHeight = Math.max(0, Number(screen?.height) || 0)
        if (logicalWidth <= 0 || logicalHeight <= 0)
            continue
        const scale = Math.max(1, Number(screen?.devicePixelRatio) || 1)
        width = Math.max(width, Math.round(logicalWidth * scale))
        height = Math.max(height, Math.round(logicalHeight * scale))
        matches += 1
    }

    if (matches === 0 || width <= 0 || height <= 0)
        return { available: false, width: 0, height: 0, matches: 0,
            error: targetName === "All Displays"
                ? "No connected displays are available"
                : "The selected display is not connected" }

    return {
        available: true,
        width: width - width % 2,
        height: height - height % 2,
        matches: matches,
        error: ""
    }
}
