pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.components

Singleton {
    id: root

    property bool hasWifi: false
    property bool wifiEnabled: false
    property bool airplaneMode: false

    readonly property alias model: wifiListModel
    ListModel { id: wifiListModel }

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

    function refresh(): void {
        if (hasWifi) {
            wifiCheckProc.running = true
            airplaneCheckProc.running = true
            wifiScanProc.running = true
        }
    }

    Process { 
        id: wifiScanProc
        command: ["nmcli", "-t", "-f", "SSID,SIGNAL,ACTIVE", "dev", "wifi"]
        stdout: StdioCollector { 
            onStreamFinished: { 
                wifiListModel.clear()
                let lines = text.trim().split("\n")
                for (let line of lines) { 
                    let parts = line.split(":")
                    if (parts.length >= 2 && parts[0] !== "") {
                        wifiListModel.append({ "name": parts[0], "signal": parseInt(parts[1]), "active": parts[2] === "yes" }) 
                    }
                } 
            } 
        } 
    }

    Process { 
        id: wifiCheckProc
        command: ["nmcli", "radio", "wifi"]
        onExited: (code) => { if (code === 0 && stdout) root.wifiEnabled = stdout.readAll().trim() === "enabled" } 
    }

    Process { 
        id: airplaneCheckProc
        command: ["nmcli", "radio", "all"]
        onExited: (code) => { if (code === 0 && stdout) root.airplaneMode = !stdout.readAll().includes("enabled") } 
    }

    BinaryCheck { 
        id: vWifi
        binary: "nmcli"
        onExistsChanged: {
            root.hasWifi = exists
            if (exists) root.refresh()
        } 
    }

    Component.onCompleted: {
    }

    Timer { 
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: false
        onTriggered: root.refresh() 
    }
}
