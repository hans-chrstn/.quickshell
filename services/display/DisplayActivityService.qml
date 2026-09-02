pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services.config

Singleton {
    id: root

    property var consumerScreens: ({})
    property int syntheticIdleState: -1
    property bool observerReady: false
    readonly property int idleTimeoutSeconds:
        ConfigService.wallpaperIdleTimeoutSeconds
    readonly property int consumers: {
        let total = 0
        for (const name in consumerScreens)
            total += Number(consumerScreens[name]) || 0
        return total
    }
    readonly property bool observing: consumers > 0
    readonly property bool idle: syntheticIdleState >= 0
        ? syntheticIdleState === 1 : idleMonitor.isIdle
    readonly property bool desktopActive: !idle

    function acquire(screenName) {
        const name = String(screenName || "").trim().slice(0, 128)
        if (name.length === 0)
            return false
        const updated = Object.assign({}, consumerScreens)
        updated[name] = (Number(updated[name]) || 0) + 1
        consumerScreens = updated
        return true
    }

    function release(screenName) {
        const name = String(screenName || "").trim().slice(0, 128)
        if (name.length === 0)
            return false
        const updated = Object.assign({}, consumerScreens)
        const count = Math.max(0, (Number(updated[name]) || 0) - 1)
        if (count > 0)
            updated[name] = count
        else
            delete updated[name]
        consumerScreens = updated
        return true
    }

    function setSyntheticIdle(value) {
        if (Quickshell.env("QS_TEST_MODE") !== "1")
            return false
        syntheticIdleState = Boolean(value) ? 1 : 0
        return true
    }

    function clearSyntheticIdle() {
        if (Quickshell.env("QS_TEST_MODE") !== "1")
            return false
        syntheticIdleState = -1
        return true
    }

    function snapshot() {
        return {
            backend: "ext-idle-notify-v1",
            observerReady: observerReady,
            observing: observing,
            consumers: consumers,
            screens: Object.assign({}, consumerScreens),
            idleTimeoutSeconds: idleTimeoutSeconds,
            idle: idle,
            desktopActive: desktopActive,
            synthetic: syntheticIdleState >= 0
        }
    }

    IdleMonitor {
        id: idleMonitor
        enabled: root.observing
        timeout: root.idleTimeoutSeconds
        respectInhibitors: true
        Component.onCompleted: root.observerReady = true
    }
}
