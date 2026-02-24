pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.components

Singleton {
    id: root

    property bool hasBluetooth: false
    property bool bluetoothEnabled: false
    property bool isScanning: false

    readonly property alias model: bluetoothListModel
    ListModel { id: bluetoothListModel }

    function toggleBluetooth(): void {
        if (!hasBluetooth) return
        Quickshell.execDetached(["rfkill", root.bluetoothEnabled ? "block" : "unblock", "bluetooth"])
        root.bluetoothEnabled = !root.bluetoothEnabled
        refresh()
    }

    function refresh(): void {
        if (hasBluetooth) {
            bluetoothCheckProc.running = true
            bluetoothListProc.running = true
        }
    }

    function startScan(): void {
        if (!bluetoothEnabled) return
        isScanning = true
        bluetoothScanProc.running = true
    }

    Process { 
        id: bluetoothListProc
        command: ["bluetoothctl", "devices"]
        stdout: StdioCollector { 
            onStreamFinished: { 
                bluetoothListModel.clear()
                parseBluetoothOutput(text) 
            } 
        } 
    }

    Process { 
        id: bluetoothScanProc
        command: ["bluetoothctl", "--timeout", "10", "scan", "on"]
        onExited: (code) => {
            root.isScanning = false
            bluetoothListProc.running = true 
        }
    }

    function parseBluetoothOutput(text) {
        let lines = text.trim().split("\n")
        for (let line of lines) { 
            let parts = line.split(" ")
            if (parts.length >= 3) {
                let addr = parts[1]
                let name = parts.slice(2).join(" ")
                let found = false
                for(let i=0; i<bluetoothListModel.count; i++) {
                    if(bluetoothListModel.get(i).address === addr) {
                        found = true
                        break
                    }
                }
                if (!found) {
                    bluetoothListModel.append({ "name": name, "address": addr, "active": false }) 
                }
            }
        } 
    }

    Process { 
        id: bluetoothCheckProc
        command: ["rfkill", "list", "bluetooth"]
        stdout: StdioCollector {
            onStreamFinished: root.bluetoothEnabled = !text.includes("soft blocked: yes")
        }
    }

    AvailabilityCheck { 
        binary: "bluetoothctl"
        onExistsChanged: {
            root.hasBluetooth = exists
            if (exists) root.refresh()
        } 
    }

    Timer { 
        interval: 10000
        running: true
        repeat: true
        onTriggered: root.refresh() 
    }
}
