pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.services.config
import "WallpaperOcclusionGeometry.js" as Geometry

Singleton {
    id: root

    readonly property real floatingCoverageThreshold: 0.75
    property var consumerScreens: ({})
    property var screenStates: ({})
    property string error: ""
    property int evaluationAttempt: 0
    readonly property int maximumEvaluationAttempts: 10

    readonly property int consumers: {
        let total = 0
        for (const name in consumerScreens)
            total += Number(consumerScreens[name]) || 0
        return total
    }
    readonly property bool observing: consumers > 0
    readonly property bool samplingFloatingWindows: {
        if (consumers === 0
                || !ConfigService.experimentalFloatingWallpaperSuspension)
            return false
        for (const name in screenStates) {
            if (Number(screenStates[name]?.floatingWindows) > 0)
                return true
        }
        return false
    }

    function acquire(screenName) {
        const name = String(screenName || "").trim()
        if (name.length === 0)
            return
        const updated = Object.assign({}, consumerScreens)
        updated[name] = (Number(updated[name]) || 0) + 1
        consumerScreens = updated
        ensureObservation()
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
            refreshTimer.stop()
            evaluationTimer.stop()
            floatingSampleTimer.stop()
            screenStates = ({})
            error = ""
        }
    }

    function ensureObservation() {
        if (consumers > 0)
            queueRefresh()
    }

    function queueRefresh() {
        if (consumers > 0)
            refreshTimer.restart()
    }

    function refresh() {
        if (consumers === 0)
            return
        if (typeof Hyprland.refreshToplevels !== "function") {
            error = "Native Hyprland toplevel refresh is unavailable"
            return
        }
        evaluationAttempt = 0
        Hyprland.refreshToplevels()
        evaluationTimer.restart()
    }

    function evaluateToplevels() {
        const clients = []
        const toplevels = Hyprland.toplevels?.values || []
        let incomplete = false
        for (const toplevel of toplevels) {
            const client = toplevel?.lastIpcObject
            if (client)
                clients.push(client)
            else
                incomplete = true
        }
        if (incomplete && evaluationAttempt < maximumEvaluationAttempts) {
            ++evaluationAttempt
            evaluationTimer.restart()
            return
        }
        evaluate(clients)
    }

    function monitorForScreen(name) {
        const monitors = Hyprland.monitors?.values || []
        for (const monitor of monitors) {
            if (String(monitor.name || monitor.lastIpcObject?.name || "") === name)
                return monitor
        }
        return null
    }

    function screenForName(name) {
        for (const screen of Quickshell.screens) {
            if (String(screen.name || "") === name)
                return screen
        }
        return null
    }

    function visibleWorkspaceIds(monitor) {
        const ids = ({})
        if (monitor?.activeWorkspace)
            ids[Number(monitor.activeWorkspace.id)] = true
        const special = monitor?.lastIpcObject?.specialWorkspace
        if (special && Number(special.id) !== 0)
            ids[Number(special.id)] = true
        return ids
    }

    function evaluate(clients) {
        const updated = ({})
        for (const name in consumerScreens) {
            const screen = screenForName(name)
            const monitor = monitorForScreen(name)
            if (!screen || !monitor) {
                updated[name] = { covered: false, tiledWindows: 0,
                    floatingWindows: 0, floatingCoverage: 0 }
                continue
            }

            const workspaceIds = visibleWorkspaceIds(monitor)
            const bounds = Geometry.monitorBounds(
                monitor.lastIpcObject, screen)
            const floatingRectangles = []
            let tiledWindows = 0
            let floatingWindows = 0
            for (const client of clients) {
                const workspaceId = Number(client?.workspace?.id)
                if (client?.mapped === false || client?.hidden === true
                        || (!client?.pinned && workspaceIds[workspaceId] !== true))
                    continue
                const rectangle = Geometry.clippedRectangle(client, bounds)
                if (!rectangle)
                    continue
                if (client?.floating === true) {
                    ++floatingWindows
                    floatingRectangles.push(rectangle)
                } else {
                    ++tiledWindows
                }
            }

            const screenArea = Math.max(1,
                Number(bounds.width) * Number(bounds.height))
            const floatingCoverage = Geometry.unionArea(floatingRectangles) / screenArea
            const coverageAware =
                ConfigService.experimentalFloatingWallpaperSuspension
            updated[name] = {
                covered: tiledWindows > 0
                    || floatingWindows > 0 && (!coverageAware
                        || floatingCoverage >= floatingCoverageThreshold),
                tiledWindows: tiledWindows,
                floatingWindows: floatingWindows,
                floatingCoverage: floatingCoverage
            }
        }
        screenStates = updated
        error = ""
    }

    function covered(screenName) {
        return Boolean(screenStates[String(screenName || "")]?.covered)
    }

    function known(screenName) {
        const name = String(screenName || "")
        return screenStates[name] !== undefined
    }

    function relevantEvent(name) {
        return ["openwindow", "closewindow", "movewindow", "movewindowv2",
            "changefloatingmode", "fullscreen",
            "workspace", "workspacev2", "focusedmon", "focusedmonv2",
            "activespecial", "activespecialv2", "moveworkspace",
            "moveworkspacev2", "pin"].indexOf(name) >= 0
    }

    Timer {
        id: refreshTimer
        interval: 80
        repeat: false
        onTriggered: root.refresh()
    }

    Timer {
        id: evaluationTimer
        interval: 50
        repeat: false
        onTriggered: root.evaluateToplevels()
    }

    Timer {
        id: floatingSampleTimer
        interval: 250
        repeat: true
        running: root.samplingFloatingWindows
        onTriggered: root.refresh()
    }

    Connections {
        target: Hyprland
        enabled: root.consumers > 0
        function onRawEvent(event) {
            if (root.relevantEvent(String(event?.name || "")))
                root.queueRefresh()
        }
    }

    Connections {
        target: ConfigService
        function onExperimentalFloatingWallpaperSuspensionChanged() {
            root.queueRefresh()
        }
    }

    function snapshot() {
        const toplevels = Hyprland.toplevels?.values || []
        let ipcObjects = 0
        for (const toplevel of toplevels) {
            if (toplevel?.lastIpcObject)
                ++ipcObjects
        }
        return {
            consumers: consumers,
            observing: observing,
            backend: "quickshell-native-hyprland",
            nativeToplevels: toplevels.length,
            nativeIpcObjects: ipcObjects,
            samplingFloatingWindows: samplingFloatingWindows,
            floatingSuspensionEnabled:
                ConfigService.experimentalFloatingWallpaperSuspension,
            threshold: floatingCoverageThreshold,
            screens: screenStates,
            error: error
        }
    }
}
