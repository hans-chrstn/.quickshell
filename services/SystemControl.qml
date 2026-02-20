pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

Singleton {
    id: root

    property bool hasAudio: !!sink
    property bool hasBrightness: false
    property bool hasWifi: false

    readonly property PwNode sink: Pipewire.defaultAudioSink
    
    PwObjectTracker {
        objects: [root.sink]
    }

    readonly property real volume: (sink && sink.ready && sink.audio) ? sink.audio.volume : 0.0
    readonly property bool muted: (sink && sink.ready && sink.audio) ? sink.audio.muted : false
    
    property real brightness: 0.5
    property bool wifiEnabled: false

    function updateAll(): void {
        if (hasBrightness) brightnessProc.running = true
        if (hasWifi) wifiCheckProc.running = true
    }

    function setVolume(val: real): void {
        if (sink && sink.ready && sink.audio) {
            let v = Math.max(0, Math.min(1, val))
            sink.audio.muted = false
            sink.audio.volume = v
        }
    }

    function setBrightness(val: real): void {
        if (!hasBrightness) return
        let v = Math.max(0, Math.min(1, val))
        let percent = Math.round(v * 100)
        Quickshell.execDetached(["brightnessctl", "s", percent + "%"])
        root.brightness = v
    }

    function toggleWifi(): void {
        if (!hasWifi) return
        let cmd = root.wifiEnabled ? "off" : "on"
        Quickshell.execDetached(["nmcli", "radio", "wifi", cmd])
        root.wifiEnabled = !root.wifiEnabled
    }

    Component.onCompleted: {
        checkBrightness.command = ["which", "brightnessctl"]
        checkBrightness.running = true
        checkWifi.command = ["which", "nmcli"]
        checkWifi.running = true
    }

    Process { id: checkBrightness; onExited: (code) => root.hasBrightness = (code === 0) }
    Process { id: checkWifi; onExited: (code) => root.hasWifi = (code === 0) }

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

    Process {
        id: wifiCheckProc
        command: ["nmcli", "radio", "wifi"]
        onExited: (code) => {
            if (code === 0 && stdout) {
                root.wifiEnabled = stdout.readAll().trim() === "enabled"
            }
        }
    }

    Timer { interval: 3000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.updateAll() }
}
