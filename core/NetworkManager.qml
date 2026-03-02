pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.shared

Singleton {
    id: root

    property bool hasNM: false
    property bool hasNetworkd: false
    property bool isAvailable: hasNM || hasNetworkd
    
    property bool isEnabled: true
    property bool isAirplaneModeEnabled: false
    
    property string activeInterface: ""
    property string activeType: "none" // "wifi", "ethernet", "none"
    property string activeState: "disconnected"
    property int signalStrength: 0

    readonly property string statusIcon: {
        if (root.activeType === "ethernet") {
            return ThemeManager.iconEthernet
        }
        if (root.activeType === "wifi") {
            return root.isEnabled ? ThemeManager.iconWifi : ThemeManager.iconWifiOff
        }
        return ThemeManager.iconWifiOff
    }

    property ListModel deviceModel: ListModel { }
    readonly property alias networkModel: root.deviceModel

    function refresh() {
        if (root.hasNM) {
            nmStatusProcess.running = true
            nmRadioCheck.running = true
        }
        if (root.hasNetworkd) {
            networkdStatusProcess.running = true
        }
    }

    function togglePower() {
        if (root.activeType === "wifi" && root.hasNM) {
            Quickshell.execDetached(["nmcli", "radio", "wifi", root.isEnabled ? "off" : "on"])
            root.isEnabled = !root.isEnabled
        } else {
            let target = root.isEnabled ? "block" : "unblock"
            Quickshell.execDetached(["rfkill", target, "wifi"])
            root.isEnabled = !root.isEnabled
        }
    }

    function toggleAirplaneMode() {
        if (root.hasNM) {
            let target = root.isAirplaneModeEnabled ? "on" : "off"
            Quickshell.execDetached(["nmcli", "radio", "all", target])
            root.isAirplaneModeEnabled = !root.isAirplaneModeEnabled
        } else {
            let target = root.isAirplaneModeEnabled ? "unblock" : "block"
            Quickshell.execDetached(["rfkill", target, "all"])
            root.isAirplaneModeEnabled = !root.isAirplaneModeEnabled
        }
    }

    Process {
        id: universalMonitor
        command: ["ip", "monitor", "addr", "link", "route"]
        running: true
        stdout: StdioCollector {
            onTextChanged: {
                root.refresh()
            }
        }
    }

    Process {
        id: nmRadioCheck
        command: ["nmcli", "radio", "all"]
        onExited: (code) => {
            if (code === 0 && stdout) {
                let output = stdout.readAll().toLowerCase()
                root.isEnabled = output.includes("wifi enabled")
                root.isAirplaneModeEnabled = output.includes("wwan disabled") && output.includes("wifi disabled")
            }
        }
    }

    Process {
        id: nmStatusProcess
        command: ["nmcli", "-t", "-f", "DEVICE,TYPE,STATE,CONNECTION", "device"]
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = text.trim().split("\n")
                let foundActive = false
                
                let nmDevices = []
                for (let line of lines) {
                    let parts = line.split(":")
                    if (parts.length < 3) {
                        continue
                    }
                    
                    let device = parts[0]
                    let type = parts[1]
                    let state = parts[2]
                    let conn = parts[3] || ""
                    
                    nmDevices.push({
                        "name": device,
                        "type": type,
                        "state": state,
                        "connection": conn
                    })

                    if (!foundActive && state === "connected") {
                        root.activeInterface = device
                        root.activeType = type.includes("wifi") ? "wifi" : "ethernet"
                        root.activeState = "connected"
                        foundActive = true
                    }
                }
                
                if (foundActive || !root.hasNetworkd) {
                    root.deviceModel.clear()
                    for (let d of nmDevices) {
                        root.deviceModel.append(d)
                    }
                    if (!foundActive) {
                        root.activeState = "disconnected"
                        root.activeType = "none"
                    }
                }
            }
        }
    }

    Process {
        id: networkdStatusProcess
        command: ["networkctl", "list", "--no-legend", "--no-pager"]
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = text.trim().split("\n")
                let foundActive = false
                
                let ndDevices = []
                for (let line of lines) {
                    let parts = line.trim().split(/\s+/)
                    if (parts.length < 3) {
                        continue
                    }
                    
                    let device = parts[1]
                    let type = parts[2]
                    let state = parts[3]
                    
                    ndDevices.push({
                        "name": device,
                        "type": type,
                        "state": state,
                        "connection": ""
                    })

                    if (!foundActive && (state === "routable" || state === "carrier")) {
                        root.activeInterface = device
                        root.activeType = (type.includes("wlan") || type.includes("wifi")) ? "wifi" : "ethernet"
                        root.activeState = "connected"
                        foundActive = true
                    }
                }
                
                if (foundActive || (root.activeState === "disconnected" && !root.hasNM)) {
                    root.deviceModel.clear()
                    for (let d of ndDevices) {
                        root.deviceModel.append(d)
                    }
                    if (foundActive) {
                        root.activeState = "connected"
                    }
                }
            }
        }
    }

    DependencyChecker {
        binaryName: "nmcli"
        onIsAvailableChanged: {
            root.hasNM = isAvailable
            root.refresh()
        }
    }

    DependencyChecker {
        binaryName: "networkctl"
        onIsAvailableChanged: {
            root.hasNetworkd = isAvailable
            root.refresh()
        }
    }

    Component.onCompleted: {
        root.refresh()
    }
}
