pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.components

Singleton {
    id: root

    property bool hasBluetooth: false
    property bool bluetoothEnabled: false

    readonly property alias model: bluetoothListModel
    ListModel { id: bluetoothListModel }

    function toggleBluetooth(): void {
        if (!hasBluetooth) return
        Quickshell.execDetached(["rfkill", root.bluetoothEnabled ? "block" : "unblock", "bluetooth"])
        root.bluetoothEnabled = !root.bluetoothEnabled
        bluetoothScanProc.running = true
    }

    function refresh(): void {
        if (hasBluetooth) {
            bluetoothCheckProc.running = true
            bluetoothScanProc.running = true
        }
    }

    Process { 
        id: bluetoothScanProc
        command: ["bluetoothctl", "devices"]
        stdout: StdioCollector { 
            onStreamFinished: { 
                bluetoothListModel.clear()
                let lines = text.trim().split("\n")
                for (let line of lines) { 
                    let parts = line.split(" ")
                    if (parts.length >= 3) {
                        bluetoothListModel.append({ "name": parts.slice(2).join(" "), "address": parts[1], "active": false }) 
                    }
                } 
            } 
        } 
    }

    Process { 
        id: bluetoothCheckProc
        command: ["rfkill", "list", "bluetooth"]
        onExited: (code) => { if (code === 0 && stdout) root.bluetoothEnabled = !stdout.readAll().includes("soft blocked: yes") } 
    }

    BinaryCheck { 
        id: vBT
        binary: "bluetoothctl"
        onExistsChanged: {
            root.hasBluetooth = exists
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
