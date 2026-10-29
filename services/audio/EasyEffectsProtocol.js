.pragma library

const maximumPresetNameLength = 160;

function text(value) {
    return value === undefined || value === null ? "" : String(value).trim();
}

function pipeline(value) {
    const normalized = text(value).toLowerCase();
    return normalized === "output" || normalized === "input" ? normalized : "";
}

function safePresetName(value) {
    const name = text(value);
    if (name.length === 0 || name.length > maximumPresetNameLength)
        return "";
    for (let index = 0; index < name.length; ++index) {
        const code = name.charCodeAt(index);
        if (name[index] === ":" || code < 32 || code === 127)
            return "";
    }
    return name;
}

function normalizedPresets(values) {
    const seen = new Set();
    const presets = [];
    for (const value of values || []) {
        const name = safePresetName(value);
        const key = name.toLocaleLowerCase();
        if (name.length === 0 || seen.has(key))
            continue;
        seen.add(key);
        presets.push(name);
    }
    presets.sort((left, right) => left.toLocaleLowerCase().localeCompare(right.toLocaleLowerCase()) || left.localeCompare(right));
    return presets;
}

function normalizedAbsolutePaths(values, maximumCount) {
    const seen = new Set();
    const paths = [];
    const limit = Math.max(1, Math.min(128, Math.trunc(Number(maximumCount) || 32)));
    for (const value of values || []) {
        const path = text(value).replace(/\/+$/, "");
        if (!path.startsWith("/") || path.length > 4096 || seen.has(path))
            continue;
        seen.add(path);
        paths.push(path);
        if (paths.length >= limit)
            break;
    }
    return paths;
}

function presetInventoryFromPaths(values) {
    const output = [];
    const input = [];
    for (const value of values || []) {
        const path = text(value);
        const match = path.match(/\/(output|input)\/([^/]+)\.json$/i);
        if (!match)
            continue;
        const name = safePresetName(match[2]);
        if (name.length === 0)
            continue;
        if (match[1].toLowerCase() === "output")
            output.push(name);
        else
            input.push(name);
    }
    return {
        output: normalizedPresets(output),
        input: normalizedPresets(input)
    };
}

function executablePathFromOutput(value) {
    const paths = normalizedAbsolutePaths(text(value).split(/\r?\n/), 1);
    return paths.length > 0 ? paths[0] : "";
}

function installation(nativeOutput, flatpakExitCode, flatpakOutput, flatpakExecutableOutput) {
    const nativePath = executablePathFromOutput(nativeOutput);
    const flatpakPath = normalizedAbsolutePaths(text(flatpakOutput).split(/\r?\n/), 1);
    return {
        nativeInstalled: nativePath.length > 0,
        nativePath: nativePath,
        flatpakInstalled: Number(flatpakExitCode) === 0 && flatpakPath.length > 0,
        flatpakPath: executablePathFromOutput(flatpakExecutableOutput)
    };
}

function capability(nativeInstalled, flatpakInstalled, serverReady, cliReady) {
    const native = nativeInstalled === true;
    const flatpak = flatpakInstalled === true;
    const server = serverReady === true;
    const cli = cliReady === true && (native || flatpak);
    const running = server || cli;
    return {
        installed: native || flatpak || running,
        installation: native ? "native" : flatpak ? "flatpak" : running ? "unknown" : "none",
        running: running,
        backend: server ? "local-server" : cli ? "cli" : "none",
        eventDriven: true,
        pollingIntervalMs: 0
    };
}

function cliCommand(installationValue, nativePathValue, flatpakPathValue, operation, value) {
    const installationKind = text(installationValue).toLowerCase();
    const nativePath = executablePathFromOutput(nativePathValue);
    const flatpakPath = executablePathFromOutput(flatpakPathValue);
    let prefix = [];
    if (installationKind === "native" && nativePath.length > 0)
        prefix = [nativePath];
    else if (installationKind === "flatpak" && flatpakPath.length > 0)
        prefix = [flatpakPath, "run", "com.github.wwmm.easyeffects"];
    else
        return [];
    const action = text(operation).toLowerCase();
    if (action === "query-bypass")
        return prefix.concat(["-b", "3"]);
    if (action === "set-bypass" && typeof value === "boolean")
        return prefix.concat(["-b", value ? "1" : "2"]);
    if (action === "query-preset") {
        const target = pipeline(value);
        return target.length > 0 ? prefix.concat(["-a", target]) : [];
    }
    if (action === "load-preset") {
        const preset = safePresetName(value);
        return preset.length > 0 ? prefix.concat(["-l", preset]) : [];
    }
    return [];
}

function cliLoadPlan(pipelineValue, presetValue, outputPresets, inputPresets, cliReady, busy) {
    const target = pipeline(pipelineValue);
    if (target.length === 0)
        return rejection("invalid-pipeline", "Choose an input or output effects pipeline.");
    const preset = safePresetName(presetValue);
    if (preset.length === 0)
        return rejection("invalid-preset", "The preset name is not protocol-safe.");
    if (cliReady !== true)
        return rejection("cli-unavailable", "The EasyEffects command fallback is unavailable.");
    if (busy === true)
        return rejection("busy", "Another effects change is still being confirmed.");
    const outputs = normalizedPresets(outputPresets);
    const inputs = normalizedPresets(inputPresets);
    const available = target === "output" ? outputs : inputs;
    const opposite = target === "output" ? inputs : outputs;
    if (!available.includes(preset))
        return rejection("preset-unavailable", "The selected preset is no longer available.");
    if (opposite.includes(preset))
        return rejection("ambiguous-cli-preset", "The command fallback cannot safely distinguish matching input and output preset names.");
    return {
        accepted: true,
        code: "accepted",
        message: "",
        pipeline: target,
        preset: preset
    };
}

function bypassQuery() {
    return "get_global_bypass";
}

function bypassMutation(enabled) {
    return typeof enabled === "boolean" ? "global_bypass:" + (enabled ? "1" : "0") : "";
}

function activePresetQuery(pipelineValue) {
    const target = pipeline(pipelineValue);
    return target.length > 0 ? "get_last_loaded_preset:" + target : "";
}

function loadPresetMutation(pipelineValue, presetValue) {
    const target = pipeline(pipelineValue);
    const preset = safePresetName(presetValue);
    return target.length > 0 && preset.length > 0 ? "load_preset:" + target + ":" + preset : "";
}

function parseBypassResponse(value) {
    const response = text(value);
    if (response === "1")
        return {
            accepted: true,
            bypassed: true,
            code: "confirmed"
        };
    if (response === "2")
        return {
            accepted: true,
            bypassed: false,
            code: "confirmed"
        };
    return {
        accepted: false,
        bypassed: false,
        code: response.length > 0 ? "invalid-response" : "empty-response"
    };
}

function parsePresetResponse(value) {
    const response = text(value);
    if (response.length === 0 || response.toLowerCase() === "none")
        return {
            accepted: true,
            preset: "",
            code: "none"
        };
    const preset = safePresetName(response);
    return {
        accepted: preset.length > 0,
        preset: preset,
        code: preset.length > 0 ? "confirmed" : "invalid-response"
    };
}

function loadPlan(pipelineValue, presetValue, availablePresets, serverReady, busy) {
    const target = pipeline(pipelineValue);
    if (target.length === 0)
        return rejection("invalid-pipeline", "Choose an input or output effects pipeline.");
    const preset = safePresetName(presetValue);
    if (preset.length === 0)
        return rejection("invalid-preset", "The preset name is not protocol-safe.");
    if (serverReady !== true)
        return rejection("server-unavailable", "EasyEffects is not running with its local server available.");
    if (busy === true)
        return rejection("busy", "Another effects change is still being confirmed.");
    const presets = normalizedPresets(availablePresets);
    if (!presets.includes(preset))
        return rejection("preset-unavailable", "The selected preset is no longer available.");
    return {
        accepted: true,
        code: "accepted",
        message: "",
        pipeline: target,
        preset: preset,
        command: loadPresetMutation(target, preset),
        confirmationCommand: activePresetQuery(target)
    };
}

function confirmPreset(requestedPreset, response) {
    const requested = safePresetName(requestedPreset);
    const observed = parsePresetResponse(response);
    if (requested.length === 0 || !observed.accepted || observed.preset.length === 0)
        return {
            accepted: false,
            code: observed.code,
            observed: observed.preset
        };
    return {
        accepted: observed.preset === requested,
        code: observed.preset === requested ? "confirmed" : "mismatch",
        observed: observed.preset
    };
}

function rejection(code, message) {
    return {
        accepted: false,
        code: code,
        message: message
    };
}
