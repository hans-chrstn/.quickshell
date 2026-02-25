pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.ui.shared
import qs.shared

Singleton {
    id: root

    property bool isAvailable: false
    property bool isEnabled: false
    property bool isScanning: false

    readonly property alias deviceModel: bluetoothListModel
    ListModel { id: bluetoothListModel }

    function togglePower() {
        if (!isAvailable) return
        Quickshell.execDetached(["rfkill", root.isEnabled ? "block" : "unblock", "bluetooth"])
        root.isEnabled = !root.isEnabled
        updateDevices()
    }

    function updateDevices() {
        if (isAvailable) {
            statusCheckProcess.running = true
            deviceListProcess.running = true
        }
    }

    function startScan() {
        if (!isEnabled) return
        isScanning = true
        scanProcess.running = true
    }

    Process { 
        id: deviceListProcess
        command: ["bluetoothctl", "devices"]
        stdout: StdioCollector { 
            onStreamFinished: { 
                bluetoothListModel.clear()
                parseDeviceOutput(text) 
            } 
        } 
    }

    Process { 
        id: scanProcess
        command: ["bluetoothctl", "--timeout", "10", "scan", "on"]
        onExited: (code) => {
            root.isScanning = false
            deviceListProcess.running = true 
        }
    }

    function parseDeviceOutput(text) {
        let lines = text.trim().split("\n")
        for (let line of lines) { 
            let parts = line.split(" ")
            if (parts.length >= 3) {
                let address = parts[1]
                let name = parts.slice(2).join(" ")
                let alreadyExists = false
                for(let i = 0; i < bluetoothListModel.count; i++) {
                    if(bluetoothListModel.get(i).address === address) {
                        alreadyExists = true
                        break
                    }
                }
                if (!alreadyExists) {
                    bluetoothListModel.append({ 
                        "name": name, 
                        "address": address, 
                        "isActive": false 
                    }) 
                }
            }
        } 
    }

    Process { 
        id: statusCheckProcess
        command: ["rfkill", "list", "bluetooth"]
        stdout: StdioCollector {
            onStreamFinished: root.isEnabled = !text.includes("soft blocked: yes")
        }
    }

    DependencyChecker { 
        binaryName: "bluetoothctl"
        onIsAvailableChanged: {
            root.isAvailable = isAvailable
            if (isAvailable) root.updateDevices()
        } 
    }

    Timer { 
        interval: 10000
        running: true
        repeat: true
        onTriggered: root.updateDevices() 
    }
}
