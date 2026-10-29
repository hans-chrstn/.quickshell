.pragma library
.import "EasyEffectsProtocol.js" as EasyEffectsProtocol

const maximumScenes = 32;
const maximumNameLength = 64;

function text(value) {
    return value === undefined || value === null ? "" : String(value);
}

function sceneName(value) {
    const name = text(value).replace(/[\u0000-\u001f\u007f]/g, " ").replace(/\s+/g, " ").trim();
    return name.slice(0, maximumNameLength);
}

function sceneId(value) {
    return text(value).trim().toLowerCase().replace(/[^a-z0-9._-]+/g, "-").replace(/^-+|-+$/g, "").slice(0, 96);
}

function deviceKey(value, role) {
    const key = text(value).trim().toLowerCase().slice(0, 256);
    return key.startsWith(role + "-device:") ? key : "";
}

function safeCeiling(value) {
    if (value === undefined || value === null || value === "")
        return null;
    const ceiling = Number(value);
    return Number.isFinite(ceiling) ? Math.max(0, Math.min(1.5, ceiling)) : null;
}

function normalizedScene(value) {
    const name = sceneName(value?.name);
    const id = sceneId(value?.id);
    if (name.length === 0 || id.length === 0)
        return null;
    return {
        id: id,
        name: name,
        outputPreset: EasyEffectsProtocol.safePresetName(value?.outputPreset),
        inputPreset: EasyEffectsProtocol.safePresetName(value?.inputPreset),
        outputDeviceKey: deviceKey(value?.outputDeviceKey, "output"),
        inputDeviceKey: deviceKey(value?.inputDeviceKey, "input"),
        outputCeiling: safeCeiling(value?.outputCeiling),
        inputCeiling: safeCeiling(value?.inputCeiling)
    };
}

function normalizedScenes(values) {
    const scenes = [];
    const seen = new Set();
    for (const value of Array.isArray(values) ? values : []) {
        if (scenes.length >= maximumScenes)
            break;
        const scene = normalizedScene(value);
        if (!scene || seen.has(scene.id))
            continue;
        seen.add(scene.id);
        scenes.push(scene);
    }
    return scenes;
}

function sceneForId(values, idValue) {
    const id = sceneId(idValue);
    return normalizedScenes(values).find(scene => scene.id === id) || null;
}

function uniqueId(name, values, seed) {
    const base = sceneId(name) || "scene";
    const used = new Set(normalizedScenes(values).map(scene => scene.id));
    if (!used.has(base))
        return base;
    const suffix = sceneId(seed) || "copy";
    let candidate = (base + "-" + suffix).slice(0, 96);
    if (!used.has(candidate))
        return candidate;
    for (let index = 2; index <= maximumScenes + 1; ++index) {
        candidate = (base + "-" + index).slice(0, 96);
        if (!used.has(candidate))
            return candidate;
    }
    return "";
}

function defaultKey(value, role) {
    const key = text(value?.stableKey);
    return value?.role === role + "-device" ? deviceKey(key, role) : "";
}

function capturedPreset(effects, pipeline) {
    const state = effects?.[pipeline] || ({});
    if (state.activePresetKnown !== true)
        return "";
    const activePreset = EasyEffectsProtocol.safePresetName(state.activePreset);
    return EasyEffectsProtocol.normalizedPresets(state.presets).includes(activePreset) ? activePreset : "";
}

function capture(nameValue, context, existingScenes, seed) {
    const name = sceneName(nameValue);
    if (name.length === 0)
        return rejection("invalid-name", "Enter a scene name.");
    if (text(nameValue).trim().length > maximumNameLength)
        return rejection("name-too-long", "Scene names can contain at most " + maximumNameLength + " characters.");
    if (normalizedScenes(existingScenes).length >= maximumScenes)
        return rejection("scene-limit", "Remove a scene before creating another one.");
    const id = uniqueId(name, existingScenes, seed);
    if (id.length === 0)
        return rejection("id-unavailable", "A stable scene identity could not be created.");
    const effects = context?.effects || ({});
    const scene = normalizedScene({
        id: id,
        name: name,
        outputPreset: capturedPreset(effects, "output"),
        inputPreset: capturedPreset(effects, "input"),
        outputDeviceKey: defaultKey(context?.defaultOutput, "output"),
        inputDeviceKey: defaultKey(context?.defaultInput, "input"),
        outputCeiling: context?.output?.available === true ? context.output.volume : null,
        inputCeiling: context?.input?.available === true ? context.input.volume : null
    });
    return {
        accepted: true,
        code: "captured",
        message: "",
        scene: scene,
        scenes: normalizedScenes(existingScenes).concat([scene])
    };
}

function remove(values, idValue) {
    const id = sceneId(idValue);
    const scenes = normalizedScenes(values);
    if (!scenes.some(scene => scene.id === id))
        return rejection("scene-unavailable", "The audio scene is no longer available.");
    return {
        accepted: true,
        code: "removed",
        message: "",
        id: id,
        scenes: scenes.filter(scene => scene.id !== id)
    };
}

function applyPlan(sceneValue, context) {
    const scene = normalizedScene(sceneValue);
    if (!scene)
        return rejection("invalid-scene", "The audio scene is invalid.");
    const nodes = context?.nodes || [];
    const effects = context?.effects || ({});
    const issues = [];
    const steps = [];
    appendDeviceStep(steps, issues, "output", scene.outputDeviceKey, nodes, context?.defaultOutput);
    appendDeviceStep(steps, issues, "input", scene.inputDeviceKey, nodes, context?.defaultInput);
    appendPresetStep(steps, issues, "output", scene.outputPreset, effects);
    appendPresetStep(steps, issues, "input", scene.inputPreset, effects);
    appendCeilingStep(steps, "output", scene.outputCeiling);
    appendCeilingStep(steps, "input", scene.inputCeiling);
    if (issues.length > 0)
        return {
            accepted: false,
            code: "scene-unavailable",
            message: issues[0],
            issues: issues,
            scene: scene,
            steps: []
        };
    return {
        accepted: true,
        code: steps.length > 0 ? "accepted" : "unchanged",
        message: "",
        issues: [],
        scene: scene,
        steps: steps
    };
}

function appendDeviceStep(steps, issues, role, stableKey, nodes, currentDefault) {
    if (stableKey.length === 0)
        return;
    const expectedRole = role + "-device";
    const device = nodes.find(node => text(node?.stableKey).toLowerCase() === stableKey && node?.role === expectedRole && node?.ready === true);
    if (!device) {
        issues.push("The saved " + role + " device is unavailable.");
        return;
    }
    const currentKey = defaultKey(currentDefault, role);
    if (currentKey === stableKey)
        return;
    if (currentKey.length === 0) {
        issues.push("The current " + role + " device cannot be restored safely.");
        return;
    }
    steps.push({
        kind: "device",
        role: role,
        stableKey: stableKey,
        rollback: {
            kind: "device",
            role: role,
            stableKey: currentKey
        }
    });
}

function appendPresetStep(steps, issues, pipeline, preset, effects) {
    if (preset.length === 0)
        return;
    const available = EasyEffectsProtocol.normalizedPresets(effects?.[pipeline]?.presets || []);
    if (effects?.state !== "ready" || !available.includes(preset)) {
        issues.push("The saved " + pipeline + " preset is unavailable.");
        return;
    }
    const currentKnown = effects?.[pipeline]?.activePresetKnown === true;
    const currentPreset = currentKnown ? EasyEffectsProtocol.safePresetName(effects[pipeline].activePreset) : "";
    if (currentPreset === preset)
        return;
    if (currentPreset.length === 0) {
        issues.push("The current " + pipeline + " preset cannot be restored safely.");
        return;
    }
    steps.push({
        kind: "preset",
        pipeline: pipeline,
        preset: preset,
        rollback: {
            kind: "preset",
            pipeline: pipeline,
            preset: currentPreset
        }
    });
}

function appendCeilingStep(steps, role, ceiling) {
    if (ceiling === null)
        return;
    steps.push({
        kind: "ceiling",
        role: role,
        value: ceiling
    });
}

function rejection(code, message) {
    return {
        accepted: false,
        code: code,
        message: message
    };
}
