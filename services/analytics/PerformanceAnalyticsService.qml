pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int consumers: 0
    property bool available: false
    property bool sampling: false
    property string error: ""
    property int processId: 0
    property real rssKiB: 0
    property real pssKiB: 0
    property real privateKiB: 0
    property real anonymousKiB: 0
    property real swapKiB: 0
    property int threads: 0
    property real cpuPercent: -1
    property real processUptimeSeconds: 0
    property real previousTicks: -1
    property real previousUptimeSeconds: -1

    readonly property bool observing: consumers > 0
    readonly property int sampleIntervalMs: 2000

    function acquire() {
        consumers += 1
        if (consumers === 1) {
            previousTicks = -1
            previousUptimeSeconds = -1
            refresh()
        }
    }

    function release() {
        consumers = Math.max(0, consumers - 1)
        if (consumers === 0) {
            sampleTimer.stop()
            previousTicks = -1
            previousUptimeSeconds = -1
        }
    }

    function refresh() {
        if (!observing || sampleProcess.running)
            return
        sampling = true
        sampleProcess.running = true
    }

    function numericField(fields, name, fallback) {
        const value = Number(fields[name])
        return Number.isFinite(value) ? value : fallback
    }

    function accept(output) {
        const fields = ({})
        const lines = String(output || "").split("\n")
        let statLine = ""
        for (const line of lines) {
            const separator = line.indexOf(":")
            if (separator < 1)
                continue
            const key = line.slice(0, separator).trim()
            const value = line.slice(separator + 1).trim()
            if (key === "STAT")
                statLine = value
            else
                fields[key] = value.split(/\s+/)[0]
        }

        const pid = numericField(fields, "PID", 0)
        const uptime = numericField(fields, "UPTIME", -1)
        const clockTicks = numericField(fields, "CLK", 0)
        const closeParen = statLine.lastIndexOf(")")
        const statFields = closeParen >= 0
            ? statLine.slice(closeParen + 1).trim().split(/\s+/) : []
        const processTicks = statFields.length > 12
            ? Number(statFields[11]) + Number(statFields[12]) : NaN
        const startTicks = statFields.length > 19
            ? Number(statFields[19]) : NaN

        if (pid <= 0 || uptime < 0 || clockTicks <= 0
                || !Number.isFinite(processTicks)) {
            available = false
            error = "The current process metrics could not be read"
            sampling = false
            return
        }

        if (previousTicks >= 0 && previousUptimeSeconds >= 0) {
            const elapsed = uptime - previousUptimeSeconds
            cpuPercent = elapsed > 0
                ? Math.max(0, (processTicks - previousTicks)
                    / clockTicks / elapsed * 100) : cpuPercent
        }
        previousTicks = processTicks
        previousUptimeSeconds = uptime

        processId = pid
        rssKiB = numericField(fields, "Rss", 0)
        pssKiB = numericField(fields, "Pss", 0)
        privateKiB = numericField(fields, "Private_Clean", 0)
            + numericField(fields, "Private_Dirty", 0)
        anonymousKiB = numericField(fields, "Anonymous", 0)
        swapKiB = numericField(fields, "Swap", 0)
        threads = numericField(fields, "Threads", 0)
        processUptimeSeconds = Number.isFinite(startTicks)
            ? Math.max(0, uptime - startTicks / clockTicks) : 0
        available = true
        error = ""
        sampling = false
    }

    function snapshot() {
        return {
            available: available,
            sampling: sampling,
            observing: observing,
            sampleIntervalMs: sampleIntervalMs,
            processId: processId,
            screenCount: Quickshell.screens.length,
            rssKiB: rssKiB,
            pssKiB: pssKiB,
            privateKiB: privateKiB,
            anonymousKiB: anonymousKiB,
            swapKiB: swapKiB,
            threads: threads,
            cpuPercent: cpuPercent,
            processUptimeSeconds: processUptimeSeconds,
            error: error
        }
    }

    Timer {
        id: sampleTimer
        interval: root.sampleIntervalMs
        repeat: true
        running: root.observing
        onTriggered: root.refresh()
    }

    Process {
        id: sampleProcess
        command: ["/bin/sh", "-c",
            "pid=$PPID; printf 'PID: %s\\n' \"$pid\"; "
            + "awk '/^(Rss|Pss|Private_Clean|Private_Dirty|Anonymous|Swap):/ { print }' /proc/$pid/smaps_rollup; "
            + "awk '/^Threads:/ { print }' /proc/$pid/status; "
            + "printf 'STAT: '; cat /proc/$pid/stat; "
            + "printf 'UPTIME: '; cat /proc/uptime; "
            + "printf 'CLK: '; getconf CLK_TCK"]
        stdout: StdioCollector {
            onStreamFinished: root.accept(text)
        }
        onExited: exitCode => {
            root.sampling = false
            if (exitCode !== 0) {
                root.available = false
                root.error = "Process metrics are unavailable on this system"
            }
        }
    }
}
