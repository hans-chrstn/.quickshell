.pragma library

function text(value) {
    return value === undefined || value === null ? "" : String(value);
}

function normalizedPipeline(value) {
    return value === "input" ? "input" : "output";
}

function pipelineState(effects, pipeline) {
    const key = normalizedPipeline(pipeline);
    const source = effects?.[key] || ({});
    return {
        pipeline: key,
        presets: Array.isArray(source.presets) ? source.presets : [],
        activePreset: text(source.activePreset),
        activePresetKnown: source.activePresetKnown === true
    };
}

function rows(effects, pipeline) {
    const state = pipelineState(effects, pipeline);
    const seen = ({});
    return state.presets.map(value => text(value).trim()).filter(name => {
        if (name.length === 0 || seen[name])
            return false;
        seen[name] = true;
        return true;
    }).sort((first, second) => first.localeCompare(second)).map(name => ({
                id: state.pipeline + ":" + name,
                name: name,
                pipeline: state.pipeline,
                active: state.activePresetKnown && state.activePreset === name
            }));
}

function indexForName(presetRows, presetName) {
    const name = text(presetName);
    return (Array.isArray(presetRows) ? presetRows : []).findIndex(row => row.name === name);
}

function selectionAfterChange(presetRows, presetName) {
    const values = Array.isArray(presetRows) ? presetRows : [];
    if (values.length === 0)
        return "";
    if (indexForName(values, presetName) >= 0)
        return text(presetName);
    const active = values.find(row => row.active);
    return active ? active.name : values[0].name;
}

function movedSelection(presetRows, presetName, step) {
    const values = Array.isArray(presetRows) ? presetRows : [];
    if (values.length === 0)
        return "";
    const current = indexForName(values, presetName);
    const origin = current >= 0 ? current : step < 0 ? values.length : -1;
    return values[Math.max(0, Math.min(values.length - 1, origin + step))].name;
}

function controlsReady(effects) {
    return effects?.loaded === true && effects?.state === "ready" && effects?.capability?.running === true && effects?.busy !== true;
}

function emptyMessage(effects, pipeline) {
    const state = text(effects?.state);
    if (effects?.loaded !== true || state === "idle" || state === "discovering")
        return "Discovering presets…";
    if (effects?.capability?.installed !== true)
        return "EasyEffects is not installed";
    if (effects?.capability?.running !== true)
        return "Open EasyEffects to use presets";
    if (state === "degraded")
        return text(effects?.error).trim() || "Effects are unavailable";
    return "No " + normalizedPipeline(pipeline) + " presets found";
}
