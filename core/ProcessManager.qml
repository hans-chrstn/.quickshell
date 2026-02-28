pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int updateInterval: ThemeManager.taskManagerInterval
    property bool isMonitoring: false
    property string sortBy: "cpu"

    ListModel { id: processModel }
    property alias model: processModel

    function startMonitoring() {
        isMonitoring = true
        refreshTimer.start()
        refreshProcesses()
    }

    function stopMonitoring() {
        isMonitoring = false
        refreshTimer.stop()
    }

    function refreshProcesses() {
        processScanner.running = true
    }

    Timer {
        id: refreshTimer
        interval: root.updateInterval
        repeat: true
        onTriggered: root.refreshProcesses()
    }

    Process {
        id: processScanner
        command: ["sh", "-c", "ps -eo pid,pcpu,pmem,comm --sort=-pcpu --no-headers | head -n " + (ThemeManager.taskManagerProcessLimit + 5) + " | awk 'BEGIN {print \"[\"} {if (NR>1) printf \",\"; printf \"{\\\"pid\\\":%s,\\\"cpu\\\":%s,\\\"mem\\\":%s,\\\"name\\\":\\\"%s\\\"}\", $1, $2, $3, $4} END {print \"]\"}'"]
        
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text || text.trim() === "" || !text.startsWith("[")) return
                try {
                    let data = JSON.parse(text)
                    root.updateModel(data)
                } catch (e) {
                    console.warn("ProcessManager: awk JSON failed")
                }
            }
        }
    }

    function updateModel(newProcesses) {
        newProcesses.sort((a, b) => {
            if (root.sortBy === "cpu") return b.cpu - a.cpu
            if (root.sortBy === "mem") return b.mem - a.mem
            if (root.sortBy === "pid") return a.pid - b.pid
            return a.name.localeCompare(b.name)
        })

        let count = Math.min(newProcesses.length, ThemeManager.taskManagerProcessLimit)
        let modelCount = processModel.count

        for (let i = 0; i < Math.max(count, modelCount); i++) {
            if (i < count) {
                let newData = newProcesses[i]
                if (i < modelCount) {
                    let current = processModel.get(i)
                    if (current.pid !== newData.pid || Math.abs(current.cpu - newData.cpu) > 1.0) {
                        processModel.set(i, newData)
                    }
                } else {
                    processModel.append(newData)
                }
            } else if (i < modelCount) {
                processModel.remove(count, modelCount - count)
                break
            }
        }
    }

    function killProcess(pid) {
        if (pid <= 0) return
        Quickshell.execDetached(["kill", "-9", pid.toString()])
        Qt.callLater(root.refreshProcesses)
    }
}
