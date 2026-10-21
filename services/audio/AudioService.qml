pragma Singleton

import QtQuick
import Quickshell
import qs.components.lifecycle
import qs.services.config
import "../../core/JsonCopy.js" as JsonCopy
import "AudioAliasModel.js" as AudioAliasModel
import "AudioControlPolicy.js" as AudioControlPolicy
import "AudioDeviceModel.js" as AudioDeviceModel
import "AudioPrivacyMuteModel.js" as AudioPrivacyMuteModel
import "AudioRoutePolicyModel.js" as AudioRoutePolicyModel
import "AudioStatusModel.js" as AudioStatusModel

Singleton {
    id: root

    property var inventoryConsumers: ({})
    property bool applicationRouteLease: false
    property var lastApplicationRoutePolicyResult: null
    readonly property var controlPolicy: AudioControlPolicy.normalizedPolicy({
        step: ConfigService.audioVolumeStepPercent / 100,
        outputCeiling: ConfigService.audioOutputMaximumPercent / 100,
        inputCeiling: ConfigService.audioInputMaximumPercent / 100,
        muteAtZero: ConfigService.audioMuteAtZero,
        restoreOnUnmute: ConfigService.audioRestoreOnUnmute
    })
    readonly property int inventoryConsumerCount: Object.keys(inventoryConsumers).length
    readonly property int rememberedApplicationRouteCount: Object.keys(rememberedApplicationRoutes || ({})).length
    readonly property bool inventoryRequested: inventoryConsumerCount > 0 || applicationControlCoordinator.busy || applicationRouteLease || rememberedApplicationRouteCount > 0
    readonly property bool inventoryLoaded: inventoryObserver.loaded
    readonly property bool ready: masterProvider.ready
    readonly property int revision: Number(inventoryObserver.item?.revision) || 0
    readonly property var nodes: inventoryObserver.item?.nodes || []
    readonly property var links: inventoryObserver.item?.links || []
    readonly property var applications: inventoryObserver.item?.applications || emptyApplications()
    readonly property var defaults: inventoryObserver.item?.defaults || ({
            output: masterProvider.output.available ? masterProvider.output : null,
            input: masterProvider.input.available ? masterProvider.input : null,
            preferredOutput: null,
            preferredInput: null
        })
    readonly property var roleCounts: inventoryObserver.item?.roleCounts || emptyRoleCounts()
    readonly property var inventoryHealth: AudioStatusModel.derive(inventoryLoaded, inventoryObserver.item?.ready === true, roleCounts, defaults, inventoryObserver.item?.providerError || ({}))
    readonly property var health: AudioStatusModel.deriveMaster(masterProvider.ready, masterProvider.output, masterProvider.input)
    readonly property var output: controlCoordinator.output
    readonly property var input: controlCoordinator.input
    readonly property var outputDeviceSelection: inventoryObserver.item?.outputSelection || emptyDeviceSelection("output")
    readonly property var inputDeviceSelection: inventoryObserver.item?.inputSelection || emptyDeviceSelection("input")
    readonly property var outputDeviceTransition: inventoryObserver.item?.outputTransition || emptyDeviceTransition("output")
    readonly property var inputDeviceTransition: inventoryObserver.item?.inputTransition || emptyDeviceTransition("input")
    readonly property var deviceAliases: ConfigService.audioDeviceAliases
    readonly property var rememberedApplicationRoutes: ConfigService.audioRoutePolicies
    readonly property int changeSequence: controlCoordinator.sequence
    readonly property var lastChange: controlCoordinator.lastChange
    readonly property int applicationControlRevision: applicationControlCoordinator.revision
    readonly property bool applicationRouteBusy: inventoryObserver.item?.routeBusy === true
    readonly property var applicationRouteTargets: inventoryObserver.item?.routeTargets || []
    readonly property var applicationRouteState: inventoryObserver.item?.routeDiagnostics || {
        busy: false,
        phase: "unloaded",
        targets: []
    }
    readonly property var applicationRoutePolicyState: inventoryObserver.item?.routePolicyDiagnostics || {
        policyCount: rememberedApplicationRouteCount,
        requestCount: 0,
        acceptedCount: 0,
        rejectedCount: 0,
        plans: []
    }
    readonly property var privacy: privacyProvider.state
    readonly property var privacyControl: AudioPrivacyMuteModel.controlState(privacy, input, controlCoordinator.inputPending)

    signal semanticChange(var change)
    signal deviceTransitionOccurred(var transition)

    function emptyRoleCounts() {
        return {
            outputDevices: 0,
            inputDevices: 0,
            playbackStreams: 0,
            recordingStreams: 0,
            specializedNodes: 0,
            specializedStreams: 0
        };
    }

    function emptyApplications() {
        return {
            playing: [],
            recording: [],
            playingCount: 0,
            recordingCount: 0,
            streamCount: 0
        };
    }

    function emptyDeviceSelection(role) {
        return {
            role: role,
            phase: "idle",
            requestedStableKey: "",
            requestedNodeId: -1,
            actualStableKey: "",
            preferredStableKey: "",
            code: "",
            message: "",
            sequence: 0
        };
    }

    function emptyDeviceTransition(role) {
        return {
            kind: "",
            role: role,
            fromStableKey: "",
            fromName: "",
            toStableKey: "",
            toName: "",
            message: "",
            sequence: 0
        };
    }

    function setInventoryConsumer(resourceId, requested) {
        const id = String(resourceId || "").trim().slice(0, 192);
        if (id.length === 0)
            return false;
        const enabled = Boolean(requested);
        if (Boolean(inventoryConsumers[id]) === enabled)
            return true;
        const updated = Object.assign({}, inventoryConsumers);
        if (enabled)
            updated[id] = true;
        else
            delete updated[id];
        inventoryConsumers = updated;
        return true;
    }

    function setMasterVolume(role, value) {
        return controlCoordinator.setVolume(role, value);
    }

    function setMasterMuted(role, muted) {
        return controlCoordinator.setMuted(role, muted);
    }

    function adjustMasterVolume(role, steps) {
        return controlCoordinator.adjustVolume(role, steps);
    }

    function applicationControlState(group) {
        return applicationControlCoordinator.effectiveGroup(group);
    }

    function setApplicationVolume(groupKey, value) {
        return applicationControlCoordinator.setVolume(groupKey, value);
    }

    function setApplicationMuted(groupKey, muted) {
        return applicationControlCoordinator.setMuted(groupKey, muted);
    }

    function adjustApplicationVolume(groupKey, steps) {
        return applicationControlCoordinator.adjustVolume(groupKey, steps);
    }

    function applicationStreamControlState(groupKey, stream) {
        return applicationControlCoordinator.effectiveStream(groupKey, stream);
    }

    function setApplicationStreamVolume(groupKey, sessionId, value) {
        return applicationControlCoordinator.setStreamVolume(groupKey, sessionId, value);
    }

    function setApplicationStreamMuted(groupKey, sessionId, muted) {
        return applicationControlCoordinator.setStreamMuted(groupKey, sessionId, muted);
    }

    function adjustApplicationStreamVolume(groupKey, sessionId, steps) {
        return applicationControlCoordinator.adjustStreamVolume(groupKey, sessionId, steps);
    }

    function setPreferredDevice(role, stableKey) {
        if (!inventoryLoaded || !inventoryObserver.item?.setPreferredDefault)
            return {
                accepted: false,
                code: "inventory-unavailable",
                message: "Open an audio device page before changing the preferred device.",
                role: String(role || ""),
                stableKey: String(stableKey || "")
            };
        return inventoryObserver.item.setPreferredDefault(role, stableKey);
    }

    function setApplicationRoute(groupKey, targetStableKey) {
        if (!inventoryLoaded || !inventoryObserver.item?.setApplicationRoute)
            return {
                accepted: false,
                code: "inventory-unavailable",
                message: "Open the application mixer before changing an application route.",
                groupKey: String(groupKey || ""),
                targetStableKey: String(targetStableKey || "")
            };
        const result = inventoryObserver.item.setApplicationRoute(groupKey, targetStableKey);
        if (result.accepted && inventoryObserver.item?.routeBusy === true)
            applicationRouteLease = true;
        return result;
    }

    function applicationRouteStatus() {
        return JsonCopy.value(applicationRouteState);
    }

    function privacyStatus() {
        const value = privacyProvider.snapshot();
        value.control = JsonCopy.value(privacyControl);
        return JsonCopy.value(value);
    }

    function setPrivacyMuted(muted) {
        const plan = AudioPrivacyMuteModel.requestPlan(privacy, input, muted);
        if (!plan.accepted)
            return plan;
        const result = controlCoordinator.setMuted("input", muted);
        return Object.assign({}, result, {
            scope: plan.scope,
            targetName: plan.targetName
        });
    }

    function applicationRoutePolicy(applicationKey) {
        return AudioRoutePolicyModel.policyFor(rememberedApplicationRoutes, applicationKey);
    }

    function rememberApplicationRoute(applicationKey, targetStableKey) {
        const result = AudioRoutePolicyModel.update(rememberedApplicationRoutes, applicationKey, targetStableKey);
        if (result.accepted)
            ConfigService.setAudioRoutePolicies(result.policies);
        return result;
    }

    function clearRememberedApplicationRoutes() {
        const result = AudioRoutePolicyModel.clear(rememberedApplicationRoutes);
        ConfigService.setAudioRoutePolicies(result.policies);
        return result;
    }

    function deviceAlias(stableKey) {
        return AudioAliasModel.aliasFor(deviceAliases, stableKey);
    }

    function deviceDisplayName(device) {
        return AudioAliasModel.displayName(device, deviceAliases);
    }

    function setDeviceAlias(stableKey, alias) {
        if (!inventoryLoaded)
            return {
                accepted: false,
                code: "inventory-unavailable",
                message: "Open an audio device page before renaming a device.",
                stableKey: String(stableKey || "")
            };
        const plan = AudioAliasModel.requestPlan(nodes, deviceAliases, stableKey, alias);
        if (!plan.accepted)
            return plan;
        ConfigService.setAudioDeviceAliases(plan.aliases);
        return {
            accepted: true,
            code: plan.code,
            message: "",
            stableKey: plan.stableKey,
            alias: plan.alias,
            originalName: plan.originalName
        };
    }

    function cycleOutput(direction) {
        if (!inventoryLoaded)
            return {
                accepted: false,
                code: "inventory-unavailable",
                message: "Open the output-device page before cycling outputs."
            };
        const selection = outputDeviceSelection;
        const pending = selection?.phase === "requested" || selection?.phase === "preferred";
        const baseKey = pending ? selection.requestedStableKey : selection.actualStableKey;
        const plan = AudioDeviceModel.cyclePlan(nodes, "output-device", baseKey, direction);
        if (!plan.accepted)
            return plan;
        const result = setPreferredDevice("output", plan.target.stableKey);
        return Object.assign({}, result, {
            cycleTarget: plan.target.stableKey,
            cycleTargetName: deviceDisplayName(plan.target),
            cycleCandidateCount: plan.candidateCount
        });
    }

    function testDeviceTransition(role, kind) {
        if (Quickshell.env("QS_TEST_MODE") !== "1")
            return false;
        if (!inventoryLoaded || !inventoryObserver.item?.showTestDeviceTransition)
            return false;
        return inventoryObserver.item.showTestDeviceTransition(String(role || ""), String(kind || ""));
    }

    function testAdjustmentBurst(role, count, steps) {
        if (Quickshell.env("QS_TEST_MODE") !== "1")
            return {
                accepted: false,
                code: "test-mode-required"
            };
        const requests = Math.max(1, Math.min(64, Math.floor(Number(count) || 0)));
        const results = [];
        for (let index = 0; index < requests; index++)
            results.push(adjustMasterVolume(role, steps));
        return {
            accepted: results.every(result => result.accepted),
            count: requests,
            results: results,
            diagnostics: controlCoordinator.diagnostics()
        };
    }

    function snapshot() {
        return {
            backend: "quickshell-pipewire",
            state: health.state,
            ready: health.ready,
            eventDriven: true,
            pollingIntervalMs: 0,
            revision: revision,
            inventory: {
                requested: inventoryRequested,
                loaded: inventoryLoaded,
                consumerCount: inventoryConsumerCount,
                consumers: Object.keys(inventoryConsumers).sort(),
                state: inventoryHealth.state,
                ready: inventoryHealth.ready,
                warnings: JsonCopy.value(inventoryHealth.warnings),
                errors: JsonCopy.value(inventoryHealth.errors)
            },
            master: {
                ready: masterProvider.ready,
                revision: masterProvider.revision,
                output: JsonCopy.value(output),
                input: JsonCopy.value(input),
                nativeOutput: JsonCopy.value(masterProvider.output),
                nativeInput: JsonCopy.value(masterProvider.input),
                policy: {
                    step: controlPolicy.step,
                    outputVolumeCeiling: controlPolicy.outputCeiling,
                    inputGainCeiling: controlPolicy.inputCeiling,
                    muteAtZero: controlPolicy.muteAtZero,
                    restoreOnUnmute: controlPolicy.restoreOnUnmute
                },
                rememberedLevels: {
                    output: JsonCopy.value(controlCoordinator.outputLevelMemory),
                    input: JsonCopy.value(controlCoordinator.inputLevelMemory)
                },
                controls: JsonCopy.value(controlCoordinator.diagnostics())
            },
            trackedNodeCount: nodes.length,
            roleCounts: JsonCopy.value(roleCounts),
            defaults: JsonCopy.value(defaults),
            deviceSelection: {
                output: JsonCopy.value(outputDeviceSelection),
                input: JsonCopy.value(inputDeviceSelection)
            },
            deviceTransitions: {
                output: JsonCopy.value(outputDeviceTransition),
                input: JsonCopy.value(inputDeviceTransition)
            },
            deviceAliases: JsonCopy.value(deviceAliases),
            availability: JsonCopy.value(health.backend),
            emptyStates: Object.assign({}, JsonCopy.value(health.emptyStates), JsonCopy.value(inventoryHealth.emptyStates)),
            warnings: JsonCopy.value(health.warnings),
            errors: JsonCopy.value(health.errors),
            nodes: JsonCopy.value(nodes),
            links: JsonCopy.value(links),
            applications: JsonCopy.value(applications),
            applicationControls: JsonCopy.value(applicationControlCoordinator.diagnostics()),
            applicationRouting: applicationRouteStatus(),
            rememberedApplicationRoutes: JsonCopy.value(rememberedApplicationRoutes),
            applicationRoutePolicy: JsonCopy.value(applicationRoutePolicyState),
            lastApplicationRoutePolicyResult: JsonCopy.value(lastApplicationRoutePolicyResult),
            privacy: privacyStatus(),
            capabilities: {
                nodeEnumeration: "native",
                linkObservation: "native",
                defaultObservation: "native",
                preferredDefaultWrite: inventoryLoaded ? "native" : "demand-loaded",
                masterVolumeMute: "native",
                applicationRouting: inventoryLoaded ? "bounded-helper" : "demand-loaded"
            }
        };
    }

    AudioMasterProvider {
        id: masterProvider
    }

    AudioPrivacyProvider {
        id: privacyProvider
    }

    AudioControlCoordinator {
        id: controlCoordinator

        provider: masterProvider
        policy: root.controlPolicy

        onSemanticChange: change => {
            root.semanticChange(change);
        }
    }

    AudioApplicationControlCoordinator {
        id: applicationControlCoordinator

        provider: inventoryObserver.item
        policy: root.controlPolicy
    }

    LifecycleLoader {
        id: inventoryObserver

        resourceId: "audio.full-inventory"
        owner: "audio-service"
        restorationSource: "PipeWire registry and default-node events"
        classification: "active-only"
        requestedActive: root.inventoryRequested
        usageActive: root.inventoryRequested
        retentionReason: root.rememberedApplicationRouteCount > 0 ? "remembered-application-routes" : requestedActive ? "audio-inventory-consumers" : ""
        evictionReason: requestedActive ? "" : "no-audio-inventory-consumers"
        sourceComponent: Component {
            AudioInventoryProvider {
                routePolicies: root.rememberedApplicationRoutes
            }
        }
    }

    property Connections inventoryConnections: Connections {
        target: inventoryObserver.item
        ignoreUnknownSignals: true

        function onDeviceTransitionOccurred(transition) {
            root.deviceTransitionOccurred(transition);
        }

        function onRouteBusyChanged() {
            if (target?.routeBusy !== true)
                root.applicationRouteLease = false;
        }

        function onApplicationRouteResultOccurred(result) {
            if (result?.origin !== "manual" || result?.accepted !== true)
                return;
            root.lastApplicationRoutePolicyResult = root.rememberApplicationRoute(result.applicationKey, result.targetStableKey);
        }
    }
}
