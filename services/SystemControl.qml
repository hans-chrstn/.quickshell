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
    property bool hasBluetooth: false
    property bool hasDunst: false

    readonly property PwNode sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: [root.sink] }

    readonly property real volume: (sink && sink.ready && sink.audio) ? sink.audio.volume : 0.0
    readonly property bool muted: (sink && sink.ready && sink.audio) ? sink.audio.muted : false
    
    property real brightness: 0.5
    property bool wifiEnabled: false
    property bool airplaneMode: false
    property bool dndActive: false
    property bool bluetoothEnabled: false
    
    property real lastVolume: 0.5

    readonly property alias wifiModel: wifiListModel
    readonly property alias bluetoothModel: bluetoothListModel
    ListModel { id: wifiListModel }
    ListModel { id: bluetoothListModel }

    function updateAll(): void {
        if (hasBrightness) brightnessProc.running = true
        if (hasWifi) {
            wifiCheckProc.running = true
            airplaneCheckProc.running = true
            wifiScanProc.running = true
        }
        if (hasBluetooth) {
            bluetoothCheckProc.running = true
            bluetoothScanProc.running = true
        }
    }

    function setVolume(val: real): void {
        if (sink && sink.ready && sink.audio) {
            let v = Math.max(0, Math.min(1, val))
            if (v === 0 && root.volume > 0) root.lastVolume = root.volume
            sink.audio.muted = (v === 0); sink.audio.volume = v
        }
    }

    function setBrightness(val: real): void {
        if (!hasBrightness) return
        let v = Math.max(0, Math.min(1, val))
        Quickshell.execDetached(["brightnessctl", "s", Math.round(v * 100) + "%"])
        root.brightness = v
    }

    function toggleWifi(): void {
        if (!hasWifi) return
        Quickshell.execDetached(["nmcli", "radio", "wifi", root.wifiEnabled ? "off" : "on"])
        root.wifiEnabled = !root.wifiEnabled
        wifiScanProc.running = true
    }

    function toggleAirplane(): void {
        if (!hasWifi) return
        let cmd = root.airplaneMode ? "on" : "off"
        Quickshell.execDetached(["nmcli", "radio", "all", cmd === "on" ? "enabled" : "disabled"])
        root.airplaneMode = !root.airplaneMode
    }

    function toggleDND(): void {
        if (!hasDunst) return
        root.dndActive = !root.dndActive
        Quickshell.execDetached(["dunstctl", "set-paused", root.dndActive ? "true" : "false"])
    }

    function toggleBluetooth(): void {
        if (!hasBluetooth) return
        Quickshell.execDetached(["rfkill", root.bluetoothEnabled ? "block" : "unblock", "bluetooth"])
        root.bluetoothEnabled = !root.bluetoothEnabled
        bluetoothScanProc.running = true
    }

    Process { id: wifiScanProc; command: ["nmcli", "-t", "-f", "SSID,SIGNAL,ACTIVE", "dev", "wifi"]; stdout: StdioCollector { onStreamFinished: { wifiListModel.clear(); let lines = text.trim().split("\n"); for (let line of lines) { let parts = line.split(":"); if (parts.length >= 2 && parts[0] !== "") wifiListModel.append({ "name": parts[0], "signal": parseInt(parts[1]), "active": parts[2] === "yes" }) } } } }
    Process { id: bluetoothScanProc; command: ["bluetoothctl", "devices"]; stdout: StdioCollector { onStreamFinished: { bluetoothListModel.clear(); let lines = text.trim().split("\n"); for (let line of lines) { let parts = line.split(" "); if (parts.length >= 3) bluetoothListModel.append({ "name": parts.slice(2).join(" "), "address": parts[1], "active": false }) } } } }
    Process { id: brightnessProc; command: ["brightnessctl", "g", "m"]; onExited: (code) => { if (code === 0 && stdout) { let out = stdout.readAll().trim().split("\n"); if (out.length >= 2) root.brightness = parseInt(out[0]) / parseInt(out[1]) } } }
    Process { id: wifiCheckProc; command: ["nmcli", "radio", "wifi"]; onExited: (code) => { if (code === 0 && stdout) root.wifiEnabled = stdout.readAll().trim() === "enabled" } }
    Process { id: airplaneCheckProc; command: ["nmcli", "radio", "all"]; onExited: (code) => { if (code === 0 && stdout) root.airplaneMode = !stdout.readAll().includes("enabled") } }
    Process { id: bluetoothCheckProc; command: ["rfkill", "list", "bluetooth"]; onExited: (code) => { if (code === 0 && stdout) root.bluetoothEnabled = !stdout.readAll().includes("soft blocked: yes") } }

    Process { id: vBright; command: ["which", "brightnessctl"]; onExited: (code) => root.hasBrightness = (code === 0) }
    Process { id: vWifi; command: ["which", "nmcli"]; onExited: (code) => root.hasWifi = (code === 0) }
    Process { id: vBT; command: ["which", "bluetoothctl"]; onExited: (code) => root.hasBluetooth = (code === 0) }
    Process { id: vDunst; command: ["which", "dunstctl"]; onExited: (code) => root.hasDunst = (code === 0) }

    Component.onCompleted: {
        vBright.running = true
        vWifi.running = true
        vBT.running = true
        vDunst.running = true
    }

    Timer { interval: 5000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.updateAll() }
}
