pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property int cpuNiceLevel: 10
    readonly property int ioPriorityClass: 2
    readonly property int ioPriorityLevel: 7

    property bool niceChecked: false
    property bool ioniceChecked: false
    property string nicePath: ""
    property string ionicePath: ""

    readonly property bool ready: niceChecked && ioniceChecked
    readonly property bool cpuPriorityAvailable: nicePath.length > 0
    readonly property bool ioPriorityAvailable: ionicePath.length > 0

    function wrap(command) {
        const base = Array.from(command || [])
        if (base.length === 0)
            return base
        let wrapped = base
        if (ioPriorityAvailable) {
            wrapped = [ionicePath, "-c", String(ioPriorityClass),
                "-n", String(ioPriorityLevel)].concat(wrapped)
        }
        if (cpuPriorityAvailable) {
            wrapped = [nicePath, "-n", String(cpuNiceLevel)].concat(wrapped)
        }
        return wrapped
    }

    function snapshot() {
        return {
            ready: ready,
            cpu: {
                available: cpuPriorityAvailable,
                backend: cpuPriorityAvailable ? nicePath : "direct",
                niceLevel: cpuPriorityAvailable ? cpuNiceLevel : 0
            },
            io: {
                available: ioPriorityAvailable,
                backend: ioPriorityAvailable ? ionicePath : "direct",
                priorityClass: ioPriorityAvailable ? ioPriorityClass : 0,
                priorityLevel: ioPriorityAvailable ? ioPriorityLevel : 0
            }
        }
    }

    Component.onCompleted: {
        niceCheck.command = ["/bin/sh", "-c", "command -v nice"]
        ioniceCheck.command = ["/bin/sh", "-c", "command -v ionice"]
        niceCheck.running = true
        ioniceCheck.running = true
    }

    Process {
        id: niceCheck
        property string output: ""
        stdout: StdioCollector { onStreamFinished: niceCheck.output = text }
        onExited: exitCode => {
            root.nicePath = exitCode === 0 ? output.trim() : ""
            root.niceChecked = true
        }
    }

    Process {
        id: ioniceCheck
        property string output: ""
        stdout: StdioCollector { onStreamFinished: ioniceCheck.output = text }
        onExited: exitCode => {
            root.ionicePath = exitCode === 0 ? output.trim() : ""
            root.ioniceChecked = true
        }
    }
}
