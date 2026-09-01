pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    id: root

    property var consumerScreens: ({})
    property var poweredScreens: ({})
    property string error: ""

    readonly property int consumers: {
        let total = 0
        for (const name in consumerScreens)
            total += Number(consumerScreens[name]) || 0
        return total
    }
    readonly property bool observing: consumers > 0

    function acquire(screenName) {
        const name = String(screenName || "").trim()
        if (name.length === 0)
            return
        const updated = Object.assign({}, consumerScreens)
        updated[name] = (Number(updated[name]) || 0) + 1
        consumerScreens = updated
        refresh()
    }

    function release(screenName) {
        const name = String(screenName || "").trim()
        const updated = Object.assign({}, consumerScreens)
        const count = Math.max(0, (Number(updated[name]) || 0) - 1)
        if (count > 0)
            updated[name] = count
        else
            delete updated[name]
        consumerScreens = updated
        if (consumers === 0) {
            evaluationTimer.stop()
            poweredScreens = ({})
            error = ""
        }
    }

    function refresh() {
        if (consumers === 0)
            return
        if (typeof Hyprland.refreshMonitors !== "function") {
            error = "Native Hyprland monitor refresh is unavailable"
            return
        }
        Hyprland.refreshMonitors()
        evaluationTimer.restart()
    }

    function evaluate() {
        const updated = ({})
        const monitors = Hyprland.monitors?.values || []
        for (const name in consumerScreens) {
            let powered = true
            for (const monitor of monitors) {
                const data = monitor?.lastIpcObject || ({})
                if (String(monitor?.name || data.name || "") !== name)
                    continue
                powered = data.dpmsStatus !== false && data.disabled !== true
                break
            }
            updated[name] = powered
        }
        poweredScreens = updated
        error = ""
    }

    function powered(screenName) {
        const name = String(screenName || "")
        return poweredScreens[name] !== false
    }

    function known(screenName) {
        const name = String(screenName || "")
        return poweredScreens[name] !== undefined
    }

    Timer {
        interval: 2000
        repeat: true
        running: root.observing
        onTriggered: root.refresh()
    }

    Timer {
        id: evaluationTimer
        interval: 50
        repeat: false
        onTriggered: root.evaluate()
    }

    Connections {
        target: Hyprland
        enabled: root.observing
        function onRawEvent(event) {
            const name = String(event?.name || "")
            if (name === "monitoradded" || name === "monitoraddedv2"
                    || name === "monitorremoved" || name === "monitorremovedv2")
                root.refresh()
        }
    }

    function snapshot() {
        return {
            consumers: consumers,
            observing: observing,
            intervalMs: 2000,
            backend: "quickshell-native-hyprland",
            screens: poweredScreens,
            error: error
        }
    }
}
