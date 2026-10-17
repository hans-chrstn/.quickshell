import QtQuick
import Quickshell
import Quickshell.Io
import qs.core

Item {
    id: root
    visible: false

    required property int durationMs
    property int generation: 0
    readonly property bool busy: probeProcess.running

    signal completed(string output)

    function start(path) {
        if (busy || String(path || "").length === 0)
            return false
        generation += 1
        probeProcess.output = ""
        probeProcess.operationGeneration = generation
        probeProcess.environment = {
            QT_LOGGING_RULES: "qt.multimedia.ffmpeg.hwaccel=true;"
                + "qt.multimedia.ffmpeg.hwaccelvaapi=true;"
                + "qt.multimedia.ffmpeg.streamdecoder=true",
            QS_CODEC_PROBE_URL: String(LocalUrl.fromPath(path))
        }
        probeProcess.command = ["/proc/self/exe", "-p",
            Quickshell.shellPath(
                "services/hardware/probes/VideoHardwareProbe.qml"),
            "--no-color", "-v"]
        probeProcess.running = true
        timeoutTimer.restart()
        return true
    }

    function cancel() {
        if (!busy)
            return false
        generation += 1
        timeoutTimer.stop()
        probeProcess.signal(15)
        return true
    }

    Process {
        id: probeProcess
        property int operationGeneration: 0
        property string output: ""
        stdout: StdioCollector {
            onStreamFinished: probeProcess.output += "\n" + text
        }
        stderr: StdioCollector {
            onStreamFinished: probeProcess.output += "\n" + text
        }
        onExited: exitCode => {
            if (operationGeneration !== root.generation)
                return
            timeoutTimer.stop()
            root.completed(output)
        }
    }

    Timer {
        id: timeoutTimer
        interval: root.durationMs
        onTriggered: {
            if (probeProcess.running)
                probeProcess.signal(15)
        }
    }
}
