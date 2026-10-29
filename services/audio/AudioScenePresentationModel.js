.pragma library

function text(value) {
    return value === undefined || value === null ? "" : String(value);
}

function percent(value) {
    if (value === undefined || value === null || value === "")
        return "";
    const numeric = Number(value);
    return Number.isFinite(numeric) ? Math.round(numeric * 100) + "%" : "";
}

function summary(scene) {
    const parts = [];
    const outputPreset = text(scene?.outputPreset).trim();
    const inputPreset = text(scene?.inputPreset).trim();
    if (outputPreset.length > 0)
        parts.push(outputPreset + " output");
    if (inputPreset.length > 0)
        parts.push(inputPreset + " input");
    const levels = [percent(scene?.outputCeiling), percent(scene?.inputCeiling)].filter(value => value.length > 0);
    if (levels.length > 0)
        parts.push(levels.join(" / "));
    if (parts.length === 0)
        return "Saved devices";
    return parts.join("  ·  ");
}

function rows(scenes) {
    return (Array.isArray(scenes) ? scenes : []).map(scene => ({
                id: text(scene?.id),
                name: text(scene?.name),
                summary: summary(scene),
                scene: scene
            })).filter(row => row.id.length > 0 && row.name.length > 0);
}

function indexForId(sceneRows, sceneId) {
    return (Array.isArray(sceneRows) ? sceneRows : []).findIndex(row => row.id === text(sceneId));
}

function selectionAfterChange(sceneRows, sceneId) {
    const values = Array.isArray(sceneRows) ? sceneRows : [];
    if (values.length === 0)
        return "";
    return indexForId(values, sceneId) >= 0 ? text(sceneId) : values[0].id;
}

function movedSelection(sceneRows, sceneId, step) {
    const values = Array.isArray(sceneRows) ? sceneRows : [];
    if (values.length === 0)
        return "";
    const current = indexForId(values, sceneId);
    const origin = current >= 0 ? current : step < 0 ? values.length : -1;
    return values[Math.max(0, Math.min(values.length - 1, origin + step))].id;
}
