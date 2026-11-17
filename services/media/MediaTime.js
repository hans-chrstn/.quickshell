.pragma library

function boundedSeconds(value, length) {
    const duration = Number(length);
    const requested = Number(value);
    if (!Number.isFinite(duration) || duration <= 0 || !Number.isFinite(requested))
        return 0;
    return Math.max(0, Math.min(duration, requested));
}

function fraction(value, length) {
    const duration = Number(length);
    if (!Number.isFinite(duration) || duration <= 0)
        return 0;
    return boundedSeconds(value, duration) / duration;
}

function clock(value) {
    const seconds = Math.max(0, Math.trunc(Number(value) || 0));
    const minutes = Math.floor(seconds / 60);
    const hours = Math.floor(minutes / 60);
    const minutePart = hours > 0 ? String(minutes % 60).padStart(2, "0") : String(minutes);
    return (hours > 0 ? hours + ":" : "") + minutePart + ":" + String(seconds % 60).padStart(2, "0");
}
