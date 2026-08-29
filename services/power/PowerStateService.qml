pragma Singleton

import QtQuick
import Quickshell
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

    Loader {
        id: provider
        active: root.optionEnabled && !root.syntheticActive
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
                : provider.active ? "upower" : "disabled",
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
