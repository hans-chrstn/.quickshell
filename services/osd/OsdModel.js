.pragma library

function normalized(kind, value, muted, screenName) {
    const category = String(kind || "");
    if (!["volume", "microphone", "brightness"].includes(category))
        return null;
    const numeric = Number(value);
    if (!Number.isFinite(numeric))
        return null;
    const level = Math.max(0, Math.min(1, numeric));
    const isMuted = muted === true;
    return {
        kind: category,
        level: level,
        muted: isMuted,
        screenName: String(screenName || ""),
        title: category === "microphone" ? "Microphone" : category === "brightness" ? "Brightness" : "Volume",
        glyph: category === "microphone" ? isMuted ? "microphoneMuted" : "microphone" : category === "brightness" ? "sun" : isMuted || level <= 0.001 ? "volumeMuted" : level < 0.45 ? "volumeLow" : "volumeHigh",
        valueText: isMuted ? "Muted" : Math.round(level * 100) + "%"
    };
}

function backlightFromBrightnessctl(text) {
    const line = String(text || "").split("\n").find(entry => entry.includes(",backlight,"));
    if (!line)
        return null;
    const fields = line.trim().split(",");
    const maximum = Number(fields[4]);
    const current = Number(fields[2]);
    if (!fields[0] || !Number.isFinite(maximum) || maximum <= 0 || !Number.isFinite(current))
        return null;
    return {
        name: fields[0],
        current: current,
        maximum: maximum,
        level: Math.max(0, Math.min(1, current / maximum))
    };
}
