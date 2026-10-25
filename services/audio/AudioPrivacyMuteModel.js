.pragma library

function text(value) {
    return value === undefined || value === null ? "" : String(value).trim();
}

function targetName(input) {
    return text(input?.name) || "Default input";
}

function controlState(privacy, input, pending) {
    const captureActive = privacy?.microphoneActive === true;
    const targetAvailable = input?.available === true && input?.ready === true && input?.capabilities?.muteWrite === true;
    return {
        scope: "default-input",
        scopeLabel: "Default input only",
        detail: "Other microphone paths are not blocked",
        captureActive: captureActive,
        targetAvailable: targetAvailable,
        canControl: captureActive && targetAvailable,
        targetName: targetName(input),
        muted: input?.muted === true,
        busy: pending?.active === true
    };
}

function requestPlan(privacy, input, muted) {
    const state = controlState(privacy, input, null);
    if (typeof muted !== "boolean") {
        return {
            accepted: false,
            code: "invalid-request",
            message: "The requested default-input mute state is invalid.",
            scope: state.scope,
            targetName: state.targetName
        };
    }
    if (!state.captureActive) {
        return {
            accepted: false,
            code: "no-active-microphone",
            message: "No active microphone capture is available.",
            scope: state.scope,
            targetName: state.targetName
        };
    }
    if (!state.targetAvailable) {
        return {
            accepted: false,
            code: "default-input-unavailable",
            message: "The default input does not expose a writable mute control.",
            scope: state.scope,
            targetName: state.targetName
        };
    }
    return {
        accepted: true,
        code: "ready",
        message: "",
        scope: state.scope,
        targetName: state.targetName,
        muted: muted
    };
}
