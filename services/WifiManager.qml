pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.components
import qs.utilities

Singleton {
    id: root

    property bool isAvailable: false
    property bool isEnabled: false
    property bool isAirplaneModeEnabled: false

    readonly property alias networkModel: wifiListModel
    ListModel { id: wifiListModel }

    function togglePower() {
        if (!isAvailable) return
        Quickshell.execDetached(["nmcli", "radio", "wifi", root.isEnabled ? "off" : "on"])
        root.isEnabled = !root.isEnabled
        updateNetworks()
    }

    function toggleAirplaneMode() {
        if (!isAvailable) return
        let targetState = root.isAirplaneModeEnabled ? "on" : "off"
        Quickshell.execDetached(["nmcli", "radio", "all", targetState])
        root.isAirplaneModeEnabled = !root.isAirplaneModeEnabled
    }

    function updateNetworks() {
        if (isAvailable) {
            wifiCheckProcess.running = true
            airplaneCheckProcess.running = true
            wifiScanProcess.running = true
        }
    }

    Process { 
        id: wifiScanProcess
        command: ["nmcli", "-t", "-f", "SSID,SIGNAL,ACTIVE", "dev", "wifi"]
        stdout: StdioCollector { 
            onStreamFinished: { 
                wifiListModel.clear()
                let lines = text.trim().split("\n")
                for (let line of lines) { 
                    let parts = line.split(":")
                    if (parts.length >= 2 && parts[0] !== "") {
                        wifiListModel.append({ 
                            "name": parts[0], 
                            "signal": parseInt(parts[1]), 
                            "isActive": parts[2] === "yes" 
                        }) 
                    }
                } 
            } 
        } 
    }

    Process { 
        id: wifiCheckProcess
        command: ["nmcli", "radio", "wifi"]
        onExited: (code) => { 
            if (code === 0 && stdout) {
                root.isEnabled = stdout.readAll().trim() === "enabled" 
            }
        } 
    }

    Process { 
        id: airplaneCheckProcess
        command: ["nmcli", "radio", "all"]
        onExited: (code) => { 
            if (code === 0 && stdout) {
                root.isAirplaneModeEnabled = !stdout.readAll().includes("enabled") 
            }
        } 
    }

    DependencyChecker { 
        binaryName: "nmcli"
        onIsAvailableChanged: {
            root.isAvailable = isAvailable
            if (isAvailable) root.updateNetworks()
        } 
    }

    Timer { 
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: false
        onTriggered: root.updateNetworks() 
    }
}
