pragma Singleton

import QtQuick
import Quickshell
import qs.components.lifecycle
import "../../core/JsonCopy.js" as JsonCopy

Singleton {
    id: root

    property var consumers: ({})
    readonly property int consumerCount: Object.keys(consumers).length
    readonly property bool providerBusy: providerLoader.item?.busy === true
    readonly property bool requested: consumerCount > 0 || providerBusy
    readonly property bool loaded: providerLoader.loaded
    readonly property string state: providerLoader.item?.state || "unloaded"
    readonly property int revision: Number(providerLoader.item?.revision) || 0
    readonly property var capability: providerLoader.item?.capability || ({
            installed: false,
            installation: "none",
            running: false,
            backend: "none",
            eventDriven: true,
            pollingIntervalMs: 0
        })

    signal resultOccurred(var result)

    function setConsumer(resourceId, enabled) {
        const id = String(resourceId || "").trim().slice(0, 192);
        if (id.length === 0)
            return false;
        const requestedValue = enabled === true;
        if (Boolean(consumers[id]) === requestedValue)
            return true;
        const updated = Object.assign({}, consumers);
        if (requestedValue)
            updated[id] = true;
        else
            delete updated[id];
        consumers = updated;
        return true;
    }

    function refresh() {
        return providerLoader.item?.refresh() === true;
    }

    function setBypassed(enabled) {
        if (!providerLoader.item)
            return rejection("provider-unloaded", "Open the Effects page before changing effects.");
        return providerLoader.item.setBypassed(enabled);
    }

    function loadPreset(pipeline, preset) {
        if (!providerLoader.item)
            return rejection("provider-unloaded", "Open the Effects page before loading a preset.");
        return providerLoader.item.loadPreset(pipeline, preset);
    }

    function rejection(code, message) {
        return {
            accepted: false,
            code: code,
            message: message
        };
    }

    function snapshot() {
        const provider = providerLoader.item?.snapshot() || ({
                state: "unloaded",
                error: "",
                busy: false,
                revision: 0,
                capability: capability,
                nativePath: "",
                flatpakPath: "",
                socketPath: "",
                bypassed: false,
                bypassKnown: false,
                output: {
                    presets: [],
                    activePreset: "",
                    activePresetKnown: false
                },
                input: {
                    presets: [],
                    activePreset: "",
                    activePresetKnown: false
                },
                operation: null,
                lastResult: null
            });
        return Object.assign({}, JsonCopy.value(provider), {
            requested: requested,
            loaded: loaded,
            consumerCount: consumerCount,
            consumers: Object.keys(consumers).sort(),
            lifecycle: {
                classification: "active-only",
                recurringWorkWhileUnloaded: false
            }
        });
    }

    LifecycleLoader {
        id: providerLoader

        resourceId: "audio.easyeffects-provider"
        owner: "easyeffects-service"
        restorationSource: "EasyEffects preset files and local server state"
        classification: "active-only"
        requestedActive: root.requested
        usageActive: root.requested
        retentionReason: root.consumerCount > 0 ? "effects-consumers" : root.providerBusy ? "effects-operation" : ""
        evictionReason: root.requested ? "" : "no-effects-consumers"
        sourceComponent: Component {
            EasyEffectsProvider {}
        }
    }

    property Connections providerConnections: Connections {
        target: providerLoader.item
        ignoreUnknownSignals: true

        function onResultOccurred(result) {
            root.resultOccurred(result);
        }
    }
}
