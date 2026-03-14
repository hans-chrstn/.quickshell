import QtQuick
import Quickshell
import Quickshell.Io
import qs.core

Item {
    id: root

    readonly property string persistencePath: Quickshell.cachePath("chrono_alarms.json")

    property int countdownSeconds: 0
    property int lastStartedSeconds: 0
    property bool isCounting: false
    
    property string activeMode: "standard"
    property string pomodoroPhase: "inactive"
    property int completedPomodoros: 0

    readonly property ListModel alarmStore: ListModel {}

    signal alertTriggered(string label)
    signal countdownFinished()

    function initiateCountdown(seconds) {
        root.activeMode = "standard"
        root.countdownSeconds = seconds
        root.lastStartedSeconds = seconds
        root.isCounting = true
    }

    function modifyCountdown(deltaSeconds) {
        root.countdownSeconds = Math.max(
            0, 
            root.countdownSeconds + deltaSeconds
        )
        if (!root.isCounting && root.countdownSeconds > 0) {
            root.isCounting = true
        }
    }

    function toggleExecution() {
        if (root.countdownSeconds > 0) {
            root.isCounting = !root.isCounting
        }
    }

    function resetChronometer() {
        root.isCounting = false
        root.countdownSeconds = 0
        root.activeMode = "standard"
        root.pomodoroPhase = "inactive"
    }

    function revertToLastStart() {
        root.countdownSeconds = root.lastStartedSeconds
        root.isCounting = false
    }

    function startPomodoroEngine() {
        root.activeMode = "pomodoro"
        root.completedPomodoros = 0
        root.transitionToPomodoroPhase("work")
    }

    function transitionToPomodoroPhase(phase) {
        root.pomodoroPhase = phase
        root.isCounting = true
        
        if (phase === "work") {
            root.countdownSeconds = 25 * 60
        } else if (phase === "shortBreak") {
            root.countdownSeconds = 5 * 60
        } else if (phase === "longBreak") {
            root.countdownSeconds = 15 * 60
        }
    }

    function processPomodoroCompletion() {
        if (root.pomodoroPhase === "work") {
            root.completedPomodoros++
            if (root.completedPomodoros % 4 === 0) {
                root.transitionToPomodoroPhase("longBreak")
            } else {
                root.transitionToPomodoroPhase("shortBreak")
            }
        } else {
            root.transitionToPomodoroPhase("work")
        }
    }

    function registerAlarm(timeString, label) {
        root.alarmStore.append({
            "time": timeString,
            "label": label || "Alarm",
            "active": true,
            "lastFired": ""
        })
        root.persistAlarmData()
    }

    function unregisterAlarm(index) {
        if (index >= 0 && index < root.alarmStore.count) {
            root.alarmStore.remove(index)
            root.persistAlarmData()
        }
    }

    function updateAlarmState(index, isActive) {
        if (index >= 0 && index < root.alarmStore.count) {
            root.alarmStore.setProperty(
                index, 
                "active", 
                isActive
            )
            root.persistAlarmData()
        }
    }

    function getFormattedTime(total) {
        let hours = Math.floor(total / 3600)
        let minutes = Math.floor((total % 3600) / 60)
        let seconds = total % 60
        
        let result = ""
        if (hours > 0) {
            result += hours.toString().padStart(2, '0') + ":"
        }
        result += minutes.toString().padStart(2, '0') + ":"
        result += seconds.toString().padStart(2, '0')
        return result
    }

    Timer {
        id: internalTick
        interval: 1000
        running: root.isCounting
        repeat: true
        onTriggered: {
            if (root.countdownSeconds > 0) {
                root.countdownSeconds--
            } else {
                root.isCounting = false
                if (root.activeMode === "pomodoro") {
                    root.processPomodoroCompletion()
                } else {
                    root.countdownFinished()
                }
            }
        }
    }

    Timer {
        id: alarmMonitor
        interval: 15000
        running: true
        repeat: true
        onTriggered: {
            let timestamp = new Date()
            let currentTime = timestamp.getHours().toString().padStart(2, '0') 
                + ":" 
                + timestamp.getMinutes().toString().padStart(2, '0')
            
            for (let i = 0; i < root.alarmStore.count; i++) {
                let entry = root.alarmStore.get(i)
                if (entry.active && entry.time === currentTime) {
                    if (entry.lastFired !== currentTime) {
                        root.alertTriggered(entry.label)
                        root.alarmStore.setProperty(
                            i, 
                            "lastFired", 
                            currentTime
                        )
                    }
                }
            }
        }
    }

    function persistAlarmData() {
        let serialized = []
        for (let i = 0; i < root.alarmStore.count; i++) {
            let item = root.alarmStore.get(i)
            serialized.push({
                "time": item.time,
                "label": item.label,
                "active": item.active
            })
        }
        persistenceBridge.setText(JSON.stringify(serialized))
    }

    FileView {
        id: persistenceBridge
        path: root.persistencePath
        printErrors: false
        onLoaded: {
            if (status !== FileView.Ready) return
            
            let raw = text()
            if (raw && raw.trim() !== "") {
                try {
                    let parsed = JSON.parse(raw)
                    root.alarmStore.clear()
                    for (let entry of parsed) {
                        entry.lastFired = ""
                        root.alarmStore.append(entry)
                    }
                } catch (e) {
                    console.error("ChronoEngine: Persistence Restore Failed")
                }
            }
        }
    }
}
