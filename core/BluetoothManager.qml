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
    ListModel {
        id: bluetoothListModel
    }

    function togglePower() {
        if (!isAvailable) {
            return
        }
        let target = root.isEnabled ? "off" : "on"
        Quickshell.execDetached(["bluetoothctl", "power", target])
        root.isEnabled = !root.isEnabled
        
        toggleTimer.restart()
    }

    function updateDevices() {
        if (isAvailable) {
            statusCheckProcess.running = true
            deviceListProcess.running = true
            pairedListProcess.running = true
        }
    }

    function startScan() {
        if (!isEnabled) {
            return
        }
        isScanning = true
        scanProcess.running = true
    }

    Timer {
        id: toggleTimer
        interval: 500
        repeat: false
        onTriggered: {
            root.updateDevices()
        }
    }

    Process {
        id: deviceListProcess
        command: ["bluetoothctl", "devices"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.parseDeviceOutput(text, false)
            }
        }
    }

    Process {
        id: pairedListProcess
        command: ["bluetoothctl", "devices", "Paired"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.parseDeviceOutput(text, true)
            }
        }
    }

    Process {
        id: scanProcess
        command: ["bluetoothctl", "--timeout", "10", "scan", "on"]
        onExited: (code) => {
            root.isScanning = false
            deviceListProcess.running = true
            pairedListProcess.running = true
        }
    }

    function parseDeviceOutput(text, isPairedList) {
        let lines = text.trim().split("\n")
        for (let line of lines) {
            let parts = line.split(" ")
            if (parts.length >= 3) {
                let address = parts[1]
                let name = parts.slice(2).join(" ")
                
                let found = false
                for (let i = 0; i < bluetoothListModel.count; i++) {
                    let item = bluetoothListModel.get(i)
                    if (item.address === address) {
                        if (isPairedList) {
                            bluetoothListModel.setProperty(i, "isPaired", true)
                        }
                        found = true
                        break
                    }
                }
                
                if (!found && !isPairedList) {
                    bluetoothListModel.append({
                        "name": name,
                        "address": address,
                        "isActive": false,
                        "isPaired": false
                    })
                } else if (!found && isPairedList) {
                    bluetoothListModel.append({
                        "name": name,
                        "address": address,
                        "isActive": false,
                        "isPaired": true
                    })
                }
            }
        }
    }

    Process {
        id: statusCheckProcess
        command: ["bluetoothctl", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.isEnabled = text.toLowerCase().includes("powered: yes")
            }
        }
    }

    DependencyChecker {
        binaryName: "bluetoothctl"
        onIsAvailableChanged: {
            root.isAvailable = isAvailable
            if (isAvailable) {
                root.updateDevices()
            }
        }
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: {
            root.updateDevices()
        }
    }
}
