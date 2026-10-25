pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool probeChecked: false
    property bool posterChecked: false
    property string ffprobePath: ""
    property string ffmpegPath: ""

    readonly property bool ready: probeChecked && posterChecked
    readonly property string error: {
        const missing = []
        if (probeChecked && ffprobePath.length === 0) missing.push("ffprobe")
        if (posterChecked && ffmpegPath.length === 0) missing.push("ffmpeg")
        return missing.length > 0
            ? "Missing media tools: " + missing.join(", ") : ""
    }

    Component.onCompleted: {
        probeCheck.command = ["/bin/sh", "-c", "command -v ffprobe"]
        posterCheck.command = ["/bin/sh", "-c", "command -v ffmpeg"]
        probeCheck.running = true
        posterCheck.running = true
    }

    Process {
        id: probeCheck
        property string output: ""
        stdout: StdioCollector { onStreamFinished: probeCheck.output = text }
        onExited: exitCode => {
            root.ffprobePath = exitCode === 0 ? output.trim() : ""
            root.probeChecked = true
        }
    }

    Process {
        id: posterCheck
        property string output: ""
        stdout: StdioCollector { onStreamFinished: posterCheck.output = text }
        onExited: exitCode => {
            root.ffmpegPath = exitCode === 0 ? output.trim() : ""
            root.posterChecked = true
        }
    }
}
