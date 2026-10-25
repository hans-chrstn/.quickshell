.pragma library

function count(roleCounts, key) {
    return Math.max(0, Math.trunc(Number(roleCounts?.[key]) || 0));
}

function deriveMaster(ready, output, input) {
    const backendReady = Boolean(ready);
    const outputAvailable = Boolean(output?.available);
    const inputAvailable = Boolean(input?.available);
    const outputReady = outputAvailable && Boolean(output?.ready);
    const inputReady = inputAvailable && Boolean(input?.ready);
    const warnings = [];

    if (backendReady && outputAvailable && !outputReady) {
        warnings.push({
            code: "default-output-not-ready",
            message: "The default output is present but not ready for control"
        });
    }
    if (backendReady && inputAvailable && !inputReady) {
        warnings.push({
            code: "default-input-not-ready",
            message: "The default input is present but not ready for control"
        });
    }

    let state = "connecting";
    if (backendReady && !outputAvailable && !inputAvailable)
        state = "empty";
    else if (backendReady && warnings.length > 0)
        state = "degraded";
    else if (backendReady)
        state = "ready";

    return {
        state: state,
        ready: backendReady,
        backend: {
            pipewire: backendReady ? "ready" : "connecting",
            sessionManager: backendReady && (outputAvailable || inputAvailable) ? "observed" : backendReady ? "unconfirmed" : "unknown"
        },
        emptyStates: {
            noOutput: backendReady && !outputAvailable,
            noInput: backendReady && !inputAvailable
        },
        warnings: warnings,
        errors: []
    };
}

function derive(loaded, ready, roleCounts, defaults, providerError) {
    const inventoryLoaded = Boolean(loaded);
    const backendReady = Boolean(ready);
    const error = providerError && typeof providerError === "object" ? providerError : ({});
    const errorCode = String(error.code || "");
    const outputCount = count(roleCounts, "outputDevices");
    const inputCount = count(roleCounts, "inputDevices");
    const playbackCount = count(roleCounts, "playbackStreams");
    const recordingCount = count(roleCounts, "recordingStreams");
    const defaultOutput = defaults?.output || null;
    const defaultInput = defaults?.input || null;
    const warnings = [];
    const errors = [];

    if (errorCode.length > 0) {
        errors.push({
            code: errorCode,
            message: String(error.message || "Audio backend is unavailable")
        });
    }
    if (backendReady && outputCount > 0 && !defaultOutput) {
        warnings.push({
            code: "default-output-unavailable",
            message: "No default output is currently published"
        });
    }
    if (backendReady && inputCount > 0 && !defaultInput) {
        warnings.push({
            code: "default-input-unavailable",
            message: "No default input is currently published"
        });
    }

    let state = "unloaded";
    if (inventoryLoaded && errorCode.length > 0)
        state = "unavailable";
    else if (inventoryLoaded && !backendReady)
        state = "connecting";
    else if (inventoryLoaded && outputCount === 0 && inputCount === 0)
        state = "empty";
    else if (inventoryLoaded && warnings.length > 0)
        state = "degraded";
    else if (inventoryLoaded)
        state = "ready";

    const sessionManagerObserved = backendReady && Boolean(defaultOutput || defaultInput);
    return {
        state: state,
        ready: inventoryLoaded ? backendReady : null,
        backend: {
            pipewire: !inventoryLoaded ? "unloaded" : errorCode.length > 0 ? "unavailable" : backendReady ? "ready" : "connecting",
            sessionManager: sessionManagerObserved ? "observed" : backendReady ? "unconfirmed" : "unknown"
        },
        emptyStates: {
            noOutputDevices: backendReady && outputCount === 0,
            noInputDevices: backendReady && inputCount === 0,
            noPlaybackStreams: backendReady && playbackCount === 0,
            noRecordingStreams: backendReady && recordingCount === 0
        },
        warnings: warnings,
        errors: errors
    };
}
