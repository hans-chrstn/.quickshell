pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.components

Singleton {
    id: root

    property bool hasBrightness: false
    property real brightness: 0.5

    function setBrightness(val: real): void {
        if (!hasBrightness) return
        let v = Math.max(0, Math.min(1, val))
        Quickshell.execDetached(["brightnessctl", "s", Math.round(v * 100) + "%"])
        root.brightness = v
    }

    function refresh(): void {
        if (hasBrightness) brightnessProc.running = true
    }

    Process { 
        id: brightnessProc
        command: ["brightnessctl", "g", "m"]
        onExited: (code) => { 
            if (code === 0 && stdout) { 
                let out = stdout.readAll().trim().split("\n")
                if (out.length >= 2) root.brightness = parseInt(out[0]) / parseInt(out[1]) 
            } 
        } 
    }

    AvailabilityCheck { 
        binary: "brightnessctl"
        onExistsChanged: {
            root.hasBrightness = exists
            if (exists) root.refresh()
        } 
    }

    Timer { 
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: false
        onTriggered: root.refresh() 
    }
}
