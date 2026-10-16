pragma Singleton

import QtQuick
import Quickshell
import qs.components.lifecycle
import qs.services.config
import "../../core/JsonCopy.js" as JsonCopy
import "AudioAliasModel.js" as AudioAliasModel
import "AudioControlPolicy.js" as AudioControlPolicy
import "AudioDeviceModel.js" as AudioDeviceModel
import "AudioStatusModel.js" as AudioStatusModel

Singleton {
    id: root

    property var inventoryConsumers: ({})
    readonly property var controlPolicy: AudioControlPolicy.normalizedPolicy({
        step: ConfigService.audioVolumeStepPercent / 100,
        outputCeiling: ConfigService.audioOutputMaximumPercent / 100,
        inputCeiling: ConfigService.audioInputMaximumPercent / 100,
        muteAtZero: ConfigService.audioMuteAtZero,
        restoreOnUnmute: ConfigService.audioRestoreOnUnmute
    })
    readonly property int inventoryConsumerCount: Object.keys(inventoryConsumers).length
    readonly property bool inventoryRequested: inventoryConsumerCount > 0
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
    readonly property int changeSequence: controlCoordinator.sequence
    readonly property var lastChange: controlCoordinator.lastChange

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
            capabilities: {
                nodeEnumeration: "native",
                linkObservation: "native",
                defaultObservation: "native",
                preferredDefaultWrite: inventoryLoaded ? "native" : "demand-loaded",
                masterVolumeMute: "native"
            }
        };
    }

    AudioMasterProvider {
        id: masterProvider
    }

    AudioControlCoordinator {
        id: controlCoordinator

        provider: masterProvider
        policy: root.controlPolicy

        onSemanticChange: change => {
            root.semanticChange(change);
        }
    }

    LifecycleLoader {
        id: inventoryObserver

        resourceId: "audio.full-inventory"
        owner: "audio-service"
        restorationSource: "PipeWire registry and default-node events"
        classification: "active-only"
        requestedActive: root.inventoryRequested
        usageActive: root.inventoryRequested
        retentionReason: requestedActive ? "audio-inventory-consumers" : ""
        evictionReason: requestedActive ? "" : "no-audio-inventory-consumers"
        source: Qt.resolvedUrl("AudioInventoryProvider.qml")
    }

    property Connections inventoryConnections: Connections {
        target: inventoryObserver.item
        ignoreUnknownSignals: true

        function onDeviceTransitionOccurred(transition) {
            root.deviceTransitionOccurred(transition);
        }
    }
}
