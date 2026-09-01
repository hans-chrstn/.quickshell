pragma Singleton

import QtQuick
import Quickshell
import qs.components.lifecycle
import qs.services.config

Singleton {
    id: root

    readonly property bool testMode: Quickshell.env("QS_TEST_MODE") === "1"
    property bool syntheticActive: false
    property bool syntheticAvailable: false
    property bool syntheticOnBattery: false
    property real syntheticPercentage: 1

    readonly property bool optionEnabled:
        ConfigService.experimentalPauseWallpaperOnBattery
    readonly property bool nativeReady: Boolean(provider.item?.ready)
    readonly property bool nativeAvailable: Boolean(provider.item?.available)
    readonly property bool available: syntheticActive
        ? syntheticAvailable : nativeAvailable
    readonly property bool onBattery: available && (syntheticActive
        ? syntheticOnBattery : Boolean(provider.item?.onBattery))
    readonly property real percentage: syntheticActive
        ? syntheticPercentage : nativeAvailable
            ? Number(provider.item?.percentage) || 0 : 1
    readonly property bool pauseRequested:
        optionEnabled && available && onBattery

    LifecycleLoader {
        id: provider
        resourceId: "power.upower-provider"
        owner: "power-state-service"
        restorationSource: "ConfigService and native UPower state"
        classification: "active-only"
        requestedActive: root.optionEnabled && !root.syntheticActive
        retentionReason: requestedActive ? "battery-policy-enabled" : ""
        evictionReason: requestedActive ? ""
            : root.syntheticActive ? "synthetic-provider-active"
            : "battery-policy-disabled"
        sourceComponent: UPowerStateProvider {}
    }

    function setSyntheticState(available, onBattery, percentage) {
        if (!testMode)
            return false
        syntheticAvailable = Boolean(available)
        syntheticOnBattery = Boolean(onBattery)
        syntheticPercentage = Math.max(0, Math.min(1,
            Number(percentage) || 0))
        syntheticActive = true
        return true
    }

    function clearSyntheticState() {
        if (!testMode)
            return false
        syntheticActive = false
        return true
    }

    function snapshot() {
        return {
            provider: syntheticActive ? "synthetic"
                : provider.loaded ? "upower" : "disabled",
            testMode: testMode,
            nativeReady: nativeReady,
            available: available,
            onBattery: onBattery,
            percentage: percentage,
            optionEnabled: optionEnabled,
            pauseRequested: pauseRequested
        }
    }
}
