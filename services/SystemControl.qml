pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool hasAudio: false
    property bool hasBrightness: false
    property bool hasWifi: false

    property real volume: 0.0
    property bool muted: false
    property real brightness: 0.5
    property bool wifiEnabled: false

    function updateAll(): void {
        if (hasAudio) audioProc.running = true
        if (hasBrightness) brightnessProc.running = true
        if (hasWifi) wifiCheckProc.running = true
    }

    function setVolume(val: real): void {
        if (!hasAudio) return
        let v = Math.max(0, Math.min(1, val))
        Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", v.toFixed(2)])
        root.volume = v
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
        checkAudio.command = ["which", "wpctl"]
        checkAudio.running = true
        checkBrightness.command = ["which", "brightnessctl"]
        checkBrightness.running = true
        checkWifi.command = ["which", "nmcli"]
        checkWifi.running = true
    }

    Process { id: checkAudio; onExited: (code) => root.hasAudio = (code === 0) }
    Process { id: checkBrightness; onExited: (code) => root.hasBrightness = (code === 0) }
    Process { id: checkWifi; onExited: (code) => root.hasWifi = (code === 0) }

    Process {
        id: audioProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        onExited: (code) => {
            if (code === 0 && stdout) {
                let out = stdout.readAll().trim()
                root.muted = out.includes("[MUTED]")
                let match = out.match(/[0-9.]+/) 
                if (match) root.volume = parseFloat(match[0])
            }
        }
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
