pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string sessionId: Quickshell.env("XDG_SESSION_ID") || ""
    property int consumers: 0
    property bool locked: false
    property bool preparingForSleep: false
    property bool available: false
    property string error: ""
    property bool synthetic: false

    property bool toolsChecked: false
    property string loginctlPath: ""
    property string dbusMonitorPath: ""
    property bool refreshPending: false
    property bool awaitingSleepValue: false

    readonly property bool observing: consumers > 0 && monitor.running

    function acquire() {
        consumers += 1
        if (consumers === 1)
            ensureObservation()
    }

    function release() {
        consumers = Math.max(0, consumers - 1)
        if (consumers > 0)
            return
        retryTimer.stop()
        refreshPending = false
        if (monitor.running) monitor.running = false
        if (refreshProcess.running) refreshProcess.running = false
        available = false
        locked = false
        preparingForSleep = false
        synthetic = false
        awaitingSleepValue = false
    }

    function ensureObservation() {
        if (toolsChecked) {
            startObservation()
            return
        }
        if (!resolver.running) {
            resolver.output = ""
            resolver.command = [
                "/bin/sh", "-c",
                "printf 'loginctl='; command -v loginctl || true; "
                    + "printf 'dbus-monitor='; command -v dbus-monitor || true"
            ]
            resolver.running = true
        }
    }

    function startObservation() {
        if (consumers === 0)
            return
        if (sessionId.length === 0 || loginctlPath.length === 0
                || dbusMonitorPath.length === 0) {
            available = false
            error = sessionId.length === 0
                ? "The logind session ID is unavailable"
                : "Session lock tools are unavailable"
            return
        }
        error = ""
        refresh()
        if (!monitor.running) {
            monitor.command = [
                dbusMonitorPath, "--system",
                "type='signal',sender='org.freedesktop.login1',"
                    + "interface='org.freedesktop.DBus.Properties',"
                    + "member='PropertiesChanged'",
                "type='signal',sender='org.freedesktop.login1',"
                    + "path='/org/freedesktop/login1',"
                    + "interface='org.freedesktop.login1.Manager',"
                    + "member='PrepareForSleep'"
            ]
            monitor.running = true
        }
    }

    function refresh() {
        if (synthetic || consumers === 0 || loginctlPath.length === 0)
            return
        if (refreshProcess.running) {
            refreshPending = true
            return
        }
        refreshPending = false
        refreshProcess.output = ""
        refreshProcess.command = [
            loginctlPath, "show-session", sessionId,
            "--property=LockedHint", "--value"
        ]
        refreshProcess.running = true
    }

    function setTestState(lockState, sleepState) {
        if (Quickshell.env("QS_TEST_MODE") !== "1")
            return false
        synthetic = true
        available = true
        error = ""
        locked = Boolean(lockState)
        preparingForSleep = Boolean(sleepState)
        return true
    }

    function clearTestState() {
        if (Quickshell.env("QS_TEST_MODE") !== "1")
            return false
        synthetic = false
        preparingForSleep = false
        refresh()
        return true
    }

    Process {
        id: resolver
        property string output: ""
        stdout: StdioCollector { onStreamFinished: resolver.output = text }
        onExited: {
            for (const line of String(output || "").split("\n")) {
                if (line.startsWith("loginctl="))
                    root.loginctlPath = line.slice(9).trim()
                else if (line.startsWith("dbus-monitor="))
                    root.dbusMonitorPath = line.slice(13).trim()
            }
            root.toolsChecked = true
            root.startObservation()
        }
    }

    Process {
        id: refreshProcess
        property string output: ""
        stdout: StdioCollector { onStreamFinished: refreshProcess.output = text }
        onExited: exitCode => {
            if (root.consumers === 0)
                return
            if (root.synthetic)
                return
            if (exitCode === 0) {
                root.locked = output.trim().toLowerCase() === "yes"
                root.available = true
                root.error = ""
            } else {
                root.available = false
                root.error = "Session lock state is unavailable"
            }
            if (root.refreshPending)
                Qt.callLater(root.refresh)
        }
    }

    Process {
        id: monitor
        stdout: SplitParser {
            onRead: line => {
                if (root.synthetic)
                    return
                const value = String(line || "")
                if (value.indexOf('string "LockedHint"') >= 0)
                    root.refresh()
                if (value.indexOf("member=PrepareForSleep") >= 0) {
                    root.awaitingSleepValue = true
                } else if (root.awaitingSleepValue) {
                    const normalized = value.trim().toLowerCase()
                    if (normalized === "boolean true"
                            || normalized === "boolean false") {
                        root.awaitingSleepValue = false
                        root.preparingForSleep = normalized.endsWith("true")
                    }
                }
            }
        }
        onExited: {
            if (root.consumers > 0)
                retryTimer.restart()
        }
    }

    Timer {
        id: retryTimer
        interval: 5000
        onTriggered: root.startObservation()
    }

    function snapshot() {
        return {
            sessionId: sessionId,
            consumers: consumers,
            observing: observing,
            available: available,
            locked: locked,
            preparingForSleep: preparingForSleep,
            synthetic: synthetic,
            error: error
        }
    }
}
