pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.ui.shared
import qs.shared

Singleton {
    id: root

    property bool isAvailable: false
    property real level: 0.5

    function setLevel(value) {
        if (!isAvailable) return
        let clampedValue = MathUtils.clamp(value, 0, 1)
        Quickshell.execDetached(["brightnessctl", "s", Math.round(clampedValue * 100) + "%"])
        root.level = clampedValue
    }

    function updateLevel() {
        if (isAvailable) {
            brightnessProcess.running = true
        }
    }

    Process { 
        id: brightnessProcess
        command: ["brightnessctl", "g", "m"]
        onExited: (code) => { 
            if (code === 0 && stdout) { 
                let output = stdout.readAll().trim().split("\n")
                if (output.length >= 2) {
                    root.level = parseInt(output[0]) / parseInt(output[1])
                }
            } 
        } 
    }

    DependencyChecker { 
        binaryName: "brightnessctl"
        onIsAvailableChanged: {
            root.isAvailable = isAvailable
            if (isAvailable) root.updateLevel()
        } 
    }

    Timer { 
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: false
        onTriggered: root.updateLevel() 
    }
}
