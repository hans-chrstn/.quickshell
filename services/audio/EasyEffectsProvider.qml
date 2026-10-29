import QtQuick
import Quickshell
import "EasyEffectsProtocol.js" as EasyEffectsProtocol

Item {
    id: root

    property string state: "idle"
    property string error: ""
    property int revision: 0
    property int sequence: 0
    property bool busy: false
    property bool nativeInstalled: false
    property string nativePath: ""
    property bool flatpakInstalled: false
    property string flatpakPath: ""
    property bool processRunning: false
    property bool serverReady: false
    property string backend: "none"
    property bool bypassed: false
    property bool bypassKnown: false
    property var outputPresets: []
    property var inputPresets: []
    property string activeOutputPreset: ""
    property string activeInputPreset: ""
    property bool activeOutputPresetKnown: false
    property bool activeInputPresetKnown: false
    property var operation: null
    property var lastResult: null
    property string socketPath: {
        const runtime = String(Quickshell.env("XDG_RUNTIME_DIR") || "").replace(/\/+$/, "");
        return runtime.length > 0 ? runtime + "/EasyEffectsServer" : "";
    }
    readonly property bool cliReady: processRunning && (nativeInstalled || flatpakInstalled)
    readonly property var capability: EasyEffectsProtocol.capability(nativeInstalled, flatpakInstalled, serverReady, backend === "cli" && cliReady)

    signal resultOccurred(var result)

    visible: false
    width: 0
    height: 0

    function response(accepted, code, message, extra) {
        return Object.assign({
            accepted: accepted,
            code: code,
            message: message || "",
            sequence: sequence
        }, extra || ({}));
    }

    function publishOperation(changes) {
        operation = Object.assign({}, operation || ({}), changes);
    }

    function clearRuntimeState() {
        serverReady = false;
        bypassKnown = false;
        activeOutputPreset = "";
        activeInputPreset = "";
        activeOutputPresetKnown = false;
        activeInputPresetKnown = false;
    }

    function refresh() {
        if (busy)
            return false;
        sequence += 1;
        busy = true;
        state = "discovering";
        error = "";
        operation = {
            token: sequence,
            kind: "refresh",
            phase: "discovering"
        };
        if (!discovery.refresh()) {
            finish(false, "discovery-unavailable", "EasyEffects discovery could not start.");
            return false;
        }
        return true;
    }

    function setBypassed(enabled) {
        if (typeof enabled !== "boolean")
            return response(false, "invalid-bypass", "Choose whether effects should be bypassed.");
        if (!capability.running)
            return response(false, "effects-unavailable", "EasyEffects is not currently available for control.");
        if (busy)
            return response(false, "busy", "Another effects request is still active.");
        sequence += 1;
        busy = true;
        operation = {
            token: sequence,
            kind: "bypass",
            phase: "mutating",
            requestedBypass: enabled
        };
        if (!requestAction("set-bypass", "mutating", enabled, false)) {
            finish(false, "request-unavailable", "The EasyEffects request could not start.");
            return response(false, "request-unavailable", "The EasyEffects request could not start.");
        }
        return response(true, "accepted", "", {
            requestedBypass: enabled
        });
    }

    function loadPreset(pipelineValue, presetValue) {
        const target = EasyEffectsProtocol.pipeline(pipelineValue);
        const presets = target === "output" ? outputPresets : target === "input" ? inputPresets : [];
        const plan = backend === "local-server" ? EasyEffectsProtocol.loadPlan(target, presetValue, presets, serverReady, busy) : EasyEffectsProtocol.cliLoadPlan(target, presetValue, outputPresets, inputPresets, cliReady, busy);
        if (!plan.accepted)
            return response(false, plan.code, plan.message, {
                pipeline: target,
                preset: String(presetValue || "")
            });
        sequence += 1;
        busy = true;
        operation = {
            token: sequence,
            kind: "preset",
            phase: "mutating",
            pipeline: plan.pipeline,
            preset: plan.preset,
            confirmationCommand: plan.confirmationCommand
        };
        if (!requestAction("load-preset", "mutating", plan.preset, false)) {
            finish(false, "request-unavailable", "The EasyEffects request could not start.");
            return response(false, "request-unavailable", "The EasyEffects request could not start.");
        }
        return response(true, "accepted", "", {
            pipeline: plan.pipeline,
            preset: plan.preset
        });
    }

    function serverCommand(action, value) {
        if (action === "query-bypass")
            return EasyEffectsProtocol.bypassQuery();
        if (action === "set-bypass")
            return EasyEffectsProtocol.bypassMutation(value);
        if (action === "query-preset")
            return EasyEffectsProtocol.activePresetQuery(value);
        if (action === "load-preset")
            return EasyEffectsProtocol.loadPresetMutation(operation?.pipeline, value);
        return "";
    }

    function requestAction(action, phase, value, expectResponse) {
        publishOperation({
            phase: phase,
            action: action,
            actionValue: value,
            expectResponse: expectResponse === true
        });
        const token = operation?.token || 0;
        if (backend === "local-server")
            return client.request(serverCommand(action, value), expectResponse === true, token);
        if (backend === "cli") {
            const command = EasyEffectsProtocol.cliCommand(capability.installation, nativePath, flatpakPath, action, value);
            return cliClient.request(command, token);
        }
        return false;
    }

    function retryCurrentAction() {
        return requestAction(String(operation?.action || ""), String(operation?.phase || ""), operation?.actionValue, operation?.expectResponse === true);
    }

    function handleDiscovery(result) {
        if (!busy || operation?.kind !== "refresh")
            return;
        nativeInstalled = result.nativeInstalled === true;
        nativePath = String(result.nativePath || "");
        flatpakInstalled = result.flatpakInstalled === true;
        flatpakPath = String(result.flatpakPath || "");
        processRunning = result.processRunning === true;
        outputPresets = result.outputPresets || [];
        inputPresets = result.inputPresets || [];
        backend = "local-server";
        if (!requestAction("query-bypass", "querying-bypass", null, true))
            finish(false, "request-unavailable", "The EasyEffects request could not start.");
    }

    function handleCompleted(token, responseText) {
        if (!busy || token !== operation?.token)
            return;
        const kind = String(operation.kind || "");
        const phase = String(operation.phase || "");
        if (kind === "refresh") {
            if (phase === "querying-bypass") {
                const parsed = EasyEffectsProtocol.parseBypassResponse(responseText);
                if (!parsed.accepted) {
                    finish(false, parsed.code, "EasyEffects returned an invalid bypass state.");
                    return;
                }
                serverReady = backend === "local-server";
                processRunning = true;
                bypassed = parsed.bypassed;
                bypassKnown = true;
                if (!requestAction("query-preset", "querying-output-preset", "output", true))
                    finish(false, "request-unavailable", "The EasyEffects request could not start.");
            } else if (phase === "querying-output-preset") {
                const parsed = EasyEffectsProtocol.parsePresetResponse(responseText);
                if (!parsed.accepted) {
                    finish(false, parsed.code, "EasyEffects returned an invalid output preset.");
                    return;
                }
                activeOutputPreset = parsed.preset;
                activeOutputPresetKnown = true;
                if (!requestAction("query-preset", "querying-input-preset", "input", true))
                    finish(false, "request-unavailable", "The EasyEffects request could not start.");
            } else if (phase === "querying-input-preset") {
                const parsed = EasyEffectsProtocol.parsePresetResponse(responseText);
                if (!parsed.accepted) {
                    finish(false, parsed.code, "EasyEffects returned an invalid input preset.");
                    return;
                }
                activeInputPreset = parsed.preset;
                activeInputPresetKnown = true;
                finish(true, "refreshed", "");
            }
            return;
        }
        if (phase === "mutating") {
            const started = kind === "bypass" ? requestAction("query-bypass", "confirming", null, true) : requestAction("query-preset", "confirming", operation.pipeline, true);
            if (!started)
                finish(false, "request-unavailable", "The EasyEffects confirmation request could not start.");
            return;
        }
        if (phase !== "confirming")
            return;
        if (kind === "bypass") {
            const parsed = EasyEffectsProtocol.parseBypassResponse(responseText);
            if (!parsed.accepted || parsed.bypassed !== operation.requestedBypass) {
                if (parsed.accepted) {
                    bypassed = parsed.bypassed;
                    bypassKnown = true;
                }
                finish(false, parsed.accepted ? "mismatch" : parsed.code, "EasyEffects did not confirm the requested bypass state.");
                return;
            }
            bypassed = parsed.bypassed;
            bypassKnown = true;
            finish(true, "confirmed", "");
        } else {
            const confirmation = EasyEffectsProtocol.confirmPreset(operation.preset, responseText);
            if (!confirmation.accepted) {
                if (confirmation.observed.length > 0) {
                    if (operation.pipeline === "output") {
                        activeOutputPreset = confirmation.observed;
                        activeOutputPresetKnown = true;
                    } else {
                        activeInputPreset = confirmation.observed;
                        activeInputPresetKnown = true;
                    }
                }
                finish(false, confirmation.code, "EasyEffects did not confirm the requested preset.");
                return;
            }
            if (operation.pipeline === "output")
                activeOutputPreset = confirmation.observed;
            else
                activeInputPreset = confirmation.observed;
            finish(true, "confirmed", "");
        }
    }

    function handleFailure(token, code, message) {
        if (!busy || token !== operation?.token)
            return;
        if (operation?.kind === "refresh" && backend === "local-server" && cliReady && (code === "server-unavailable" || code === "server-timeout")) {
            serverReady = false;
            backend = "cli";
            if (retryCurrentAction())
                return;
        }
        clearRuntimeState();
        finish(false, code, message);
    }

    function finish(success, code, message) {
        const completedOperation = operation;
        const result = response(success, code, message, {
            kind: String(completedOperation?.kind || ""),
            pipeline: String(completedOperation?.pipeline || ""),
            preset: String(completedOperation?.preset || ""),
            requestedBypass: completedOperation?.requestedBypass
        });
        busy = false;
        operation = null;
        error = success ? "" : message;
        if (!success && completedOperation?.kind === "refresh")
            clearRuntimeState();
        if (success) {
            state = capability.running ? "ready" : capability.installed ? "stopped" : "unavailable";
            revision += 1;
        } else if (code === "server-unavailable" || code === "server-timeout") {
            backend = "none";
            state = capability.installed ? "stopped" : "unavailable";
            revision += 1;
        } else {
            state = "degraded";
        }
        lastResult = result;
        resultOccurred(result);
        return result;
    }

    function snapshot() {
        return {
            state: state,
            error: error,
            busy: busy,
            revision: revision,
            capability: capability,
            nativePath: nativePath,
            flatpakPath: flatpakPath,
            socketPath: socketPath,
            bypassed: bypassed,
            bypassKnown: bypassKnown,
            output: {
                presets: outputPresets.slice(),
                activePreset: activeOutputPreset,
                activePresetKnown: activeOutputPresetKnown
            },
            input: {
                presets: inputPresets.slice(),
                activePreset: activeInputPreset,
                activePresetKnown: activeInputPresetKnown
            },
            operation: operation,
            lastResult: lastResult
        };
    }

    EasyEffectsDiscovery {
        id: discovery
        onCompleted: result => root.handleDiscovery(result)
    }

    EasyEffectsSocketClient {
        id: client
        socketPath: root.socketPath
        onCompleted: (token, command, response) => root.handleCompleted(token, response)
        onFailed: (token, code, message) => root.handleFailure(token, code, message)
    }

    EasyEffectsCliClient {
        id: cliClient
        onCompleted: (token, response) => root.handleCompleted(token, response)
        onFailed: (token, code, message) => root.handleFailure(token, code, message)
    }

    Component.onCompleted: refresh()
}
