pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.shared

Singleton {
    id: root

    property int updateInterval: ThemeManager.taskManagerInterval
    property bool isMonitoring: false
    property string sortBy: "cpu"
    property string searchText: ""

    property real cpuUsage: 0.0
    property real memUsage: 0.0
    property real netDown: 0.0
    property real netUp: 0.0

    property var cpuHistory: []
    property var memHistory: []
    property var netDownHistory: []
    property var netUpHistory: []

    readonly property int maxHistory: 40

    property real lastNetIn: 0
    property real lastNetOut: 0
    property double lastTimestamp: 0

    ListModel { id: processModel }
    property alias model: processModel

    function startMonitoring() {
        if (root.isMonitoring) return
        root.isMonitoring = true
        refreshTimer.start()
        root.refreshProcesses()
    }

    function stopMonitoring() {
        root.isMonitoring = false
        refreshTimer.stop()
        processScanner.running = false
    }

    function refreshProcesses() {
        if (root.isMonitoring) {
            processScanner.running = true
        }
    }

    function updateHistory(array, value) {
        let newArray = [...array]
        newArray.push(value)
        if (newArray.length > root.maxHistory) {
            newArray.shift()
        }
        return newArray
    }

    Timer {
        id: refreshTimer
        interval: root.updateInterval
        repeat: true
        running: root.isMonitoring
        onTriggered: root.refreshProcesses()
    }

    Process {
        id: processScanner
        running: false
        command: [
            "sh", 
            "-c", 
            "cpu=$(top -bn1 | grep 'Cpu(s)' | awk '{print $2 + $4}'); " +
            "mem=$(free | grep Mem | awk '{print $3/$2 * 100}'); " +
            "net=$(cat /proc/net/dev | grep -v '|' | tail -n +3 | awk '{inSum+=$2; outSum+=$10} END {print inSum \" \" outSum}'); " +
            "procs=$(ps -eo pid,pcpu,pmem,comm --sort=-pcpu --no-headers | head -n " + (ThemeManager.taskManagerProcessLimit + 5) + " | awk 'BEGIN {print \"[\"} {if (NR>1) printf \",\"; printf \"{\\\"pid\\\":%s,\\\"cpu\\\":%s,\\\"mem\\\":%s,\\\"name\\\":\\\"%s\\\"}\", $1, $2, $3, $4} END {print \"]\"}'); " +
            "echo \"{\\\"cpu\\\":$cpu,\\\"mem\\\":$mem,\\\"net\\\":\\\"$net\\\",\\\"procs\\\":$procs}\""
        ]
        
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text || text.trim() === "" || !text.startsWith("{")) return
                try {
                    let data = JSON.parse(text)
                    
                    root.cpuUsage = data.cpu || 0
                    root.memUsage = data.mem || 0
                    
                    let netParts = data.net ? data.net.split(" ") : []
                    if (netParts.length >= 2) {
                        let currentIn = parseFloat(netParts[0]) || 0
                        let currentOut = parseFloat(netParts[1]) || 0
                        let now = Date.now()
                        
                        if (root.lastTimestamp > 0) {
                            let elapsed = (now - root.lastTimestamp) / 1000
                            if (elapsed > 0) {
                                root.netDown = Math.max(0, (currentIn - root.lastNetIn) / elapsed)
                                root.netUp = Math.max(0, (currentOut - root.lastNetOut) / elapsed)
                            }
                        }
                        
                        root.lastNetIn = currentIn
                        root.lastNetOut = currentOut
                        root.lastTimestamp = now
                    }

                    root.cpuHistory = root.updateHistory(root.cpuHistory, root.cpuUsage)
                    root.memHistory = root.updateHistory(root.memHistory, root.memUsage)
                    root.netDownHistory = root.updateHistory(root.netDownHistory, root.netDown)
                    root.netUpHistory = root.updateHistory(root.netUpHistory, root.netUp)

                    if (data.procs) {
                        root.updateModel(data.procs)
                    }
                } catch (e) {
                    console.warn("ProcessManager: Combined stats JSON failed")
                }
            }
        }
    }

    function updateModel(newProcesses) {
        let filteredProcesses = newProcesses
        
        if (root.searchText && root.searchText !== "") {
            filteredProcesses = FuzzySearch.filter(root.searchText, newProcesses, (p) => p.name + " " + p.pid)
        } else {
            filteredProcesses.sort((a, b) => {
                if (root.sortBy === "cpu") return b.cpu - a.cpu
                if (root.sortBy === "mem") return b.mem - a.mem
                if (root.sortBy === "pid") return a.pid - b.pid
                return a.name.localeCompare(b.name)
            })
        }

        let count = Math.min(filteredProcesses.length, ThemeManager.taskManagerProcessLimit)
        let modelCount = processModel.count

        for (let i = 0; i < Math.max(count, modelCount); i++) {
            if (i < count) {
                let newData = filteredProcesses[i]
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
