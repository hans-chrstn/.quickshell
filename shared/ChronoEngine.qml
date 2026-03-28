import QtQuick
import Quickshell
import Quickshell.Io
import qs.core

Item {
    id: root

    readonly property string chronoPersistencePath: Quickshell.cachePath("chrono.json")

    property int countdownSeconds: 0
    property int lastStartedSeconds: 0
    property bool isCounting: false
    property string activeMode: "standard"
    property string pomodoroPhase: "inactive"
    property int completedPomodoros: 0

    property int pomoWorkSeconds: 25 * 60
    property int pomoShortBreakSeconds: 5 * 60
    property int pomoLongBreakSeconds: 15 * 60

    property int stopwatchMs: 0
    property bool isStopwatchRunning: false
    readonly property ListModel stopwatchLaps: ListModel {}

    property bool autoFocusMode: true

    readonly property ListModel alarmStore: ListModel {}
    readonly property ListModel worldClockStore: ListModel {}
    readonly property ListModel presetStore: ListModel {}
    readonly property ListModel habitStore: ListModel {}
    readonly property ListModel pomoTaskStore: ListModel {}

    signal alertTriggered(string label)
    signal countdownFinished()

    function initiateCountdown(seconds) {
        root.activeMode = "standard"
        root.countdownSeconds = seconds
        root.lastStartedSeconds = seconds
        root.isCounting = true
    }

    function modifyCountdown(deltaSeconds) {
        root.countdownSeconds = Math.max(0, root.countdownSeconds + deltaSeconds)
        if (root.countdownSeconds > root.lastStartedSeconds) {
            root.lastStartedSeconds = root.countdownSeconds
        }
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
        if (root.autoFocusMode) {
            NotificationManager.isDoNotDisturbEnabled = false
        }
    }

    function revertToLastStart() {
        root.countdownSeconds = root.lastStartedSeconds
        root.isCounting = false
    }

    function addPreset(label, seconds) {
        root.presetStore.append({ "label": label, "seconds": seconds })
        root.saveData()
    }

    function removePreset(index) {
        if (index >= 0 && index < root.presetStore.count) {
            root.presetStore.remove(index)
            root.saveData()
        }
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
            root.countdownSeconds = root.pomoWorkSeconds
            if (root.autoFocusMode) NotificationManager.isDoNotDisturbEnabled = true
        } else if (phase === "shortBreak") {
            root.countdownSeconds = root.pomoShortBreakSeconds
            if (root.autoFocusMode) NotificationManager.isDoNotDisturbEnabled = false
        } else if (phase === "longBreak") {
            root.countdownSeconds = root.pomoLongBreakSeconds
            if (root.autoFocusMode) NotificationManager.isDoNotDisturbEnabled = false
        }
    }

    function processPomodoroCompletion() {
        if (root.pomodoroPhase === "work") {
            root.completedPomodoros++
            root.transitionToPomodoroPhase(root.completedPomodoros % 4 === 0 ? "longBreak" : "shortBreak")
        } else {
            root.transitionToPomodoroPhase("work")
        }
    }

    function addHabit(label, goalCount) {
        root.habitStore.append({
            "label": label,
            "count": 0,
            "goal": goalCount || 0,
            "completed": false,
            "timestamp": new Date().getTime()
        })
        root.saveData()
    }

    function removeHabit(index) {
        if (index >= 0 && index < root.habitStore.count) {
            root.habitStore.remove(index)
            root.saveData()
        }
    }

    function incrementHabit(index) {
        if (index >= 0 && index < root.habitStore.count) {
            let item = root.habitStore.get(index)
            let newCount = item.count + 1
            root.habitStore.setProperty(index, "count", newCount)
            if (item.goal > 0 && newCount >= item.goal) {
                root.habitStore.setProperty(index, "completed", true)
            }
            root.saveData()
        }
    }

    function toggleHabit(index) {
        if (index >= 0 && index < root.habitStore.count) {
            let item = root.habitStore.get(index)
            root.habitStore.setProperty(index, "completed", !item.completed)
            root.saveData()
        }
    }

    function addPomoTask(label) {
        root.pomoTaskStore.append({
            "label": label,
            "completed": false
        })
        root.saveData()
    }

    function removePomoTask(index) {
        if (index >= 0 && index < root.pomoTaskStore.count) {
            root.pomoTaskStore.remove(index)
            root.saveData()
        }
    }

    function togglePomoTask(index) {
        if (index >= 0 && index < root.pomoTaskStore.count) {
            let item = root.pomoTaskStore.get(index)
            root.pomoTaskStore.setProperty(index, "completed", !item.completed)
            root.saveData()
        }
    }

    function toggleStopwatch() {
        root.isStopwatchRunning = !root.isStopwatchRunning
    }

    function lapStopwatch() {
        if (root.stopwatchMs === 0) return
        let lastLapMs = root.stopwatchLaps.count > 0 ? root.stopwatchLaps.get(0).totalMs : 0
        root.stopwatchLaps.insert(0, {
            "time": formatMs(root.stopwatchMs),
            "diff": formatMs(root.stopwatchMs - lastLapMs),
            "totalMs": root.stopwatchMs
        })
    }

    function resetStopwatch() {
        root.isStopwatchRunning = false
        root.stopwatchMs = 0
        root.stopwatchLaps.clear()
    }

    function registerAlarm(time, label) {
        root.alarmStore.append({ "time": time, "label": label || "Alarm", "active": true, "lastFired": "" })
        root.saveData()
    }

    function unregisterAlarm(index) {
        if (index >= 0 && index < root.alarmStore.count) {
            root.alarmStore.remove(index)
            root.saveData()
        }
    }

    function updateAlarmState(index, isActive) {
        if (index >= 0 && index < root.alarmStore.count) {
            root.alarmStore.setProperty(index, "active", isActive)
            root.saveData()
        }
    }

    function addWorldClock(city, timezone) {
        root.worldClockStore.append({ "city": city, "timezone": timezone })
        root.saveData()
    }

    function removeWorldClock(index) {
        if (index >= 0 && index < root.worldClockStore.count) {
            root.worldClockStore.remove(index)
            root.saveData()
        }
    }

    function getFormattedTime(total) {
        let h = Math.floor(total / 3600)
        let m = Math.floor((total % 3600) / 60)
        let s = total % 60
        return (h > 0 ? h.toString().padStart(2, '0') + ":" : "") + m.toString().padStart(2, '0') + ":" + s.toString().padStart(2, '0')
    }

    function formatMs(ms) {
        let s = Math.floor(ms / 1000)
        let m = Math.floor(s / 60)
        let actualS = s % 60
        let actualMs = Math.floor((ms % 1000) / 10)
        return m.toString().padStart(2, '0') + ":" + actualS.toString().padStart(2, '0') + "." + actualMs.toString().padStart(2, '0')
    }

    function getZonedTime(tz) {
        try {
            return new Date().toLocaleTimeString("en-US", { 
                timeZone: tz, 
                hour12: false, 
                hour: "2-digit", 
                minute: "2-digit" 
            })
        } catch (e) {
            return "00:00"
        }
    }

    Timer {
        id: tick1s
        interval: 1000; running: root.isCounting; repeat: true
        onTriggered: {
            if (root.countdownSeconds > 0) {
                root.countdownSeconds--
            } else {
                root.isCounting = false
                if (root.activeMode === "pomodoro") {
                    root.processPomodoroCompletion()
                } else {
                    if (root.autoFocusMode) NotificationManager.isDoNotDisturbEnabled = false
                    root.countdownFinished()
                }
            }
        }
    }

    Timer {
        id: tickStopwatch
        interval: 10; running: root.isStopwatchRunning; repeat: true
        onTriggered: root.stopwatchMs += 10
    }

    Timer {
        interval: 15000; running: true; repeat: true
        onTriggered: {
            let now = new Date()
            let cur = now.getHours().toString().padStart(2, '0') + ":" + now.getMinutes().toString().padStart(2, '0')
            for (let i = 0; i < root.alarmStore.count; i++) {
                let a = root.alarmStore.get(i)
                if (a.active && a.time === cur && a.lastFired !== cur) {
                    root.alertTriggered(a.label)
                    root.alarmStore.setProperty(i, "lastFired", cur)
                }
            }
        }
    }

    function saveData() {
        let data = { 
            "alarms": [], 
            "clocks": [], 
            "presets": [], 
            "habits": [],
            "pomoTasks": [],
            "autoFocus": root.autoFocusMode,
            "pomoWork": root.pomoWorkSeconds,
            "pomoShort": root.pomoShortBreakSeconds,
            "pomoLong": root.pomoLongBreakSeconds
        }
        for (let i = 0; i < root.alarmStore.count; i++) data.alarms.push(root.alarmStore.get(i))
        for (let i = 0; i < root.worldClockStore.count; i++) data.clocks.push(root.worldClockStore.get(i))
        for (let i = 0; i < root.presetStore.count; i++) data.presets.push(root.presetStore.get(i))
        for (let i = 0; i < root.habitStore.count; i++) data.habits.push(root.habitStore.get(i))
        for (let i = 0; i < root.pomoTaskStore.count; i++) data.pomoTasks.push(root.pomoTaskStore.get(i))
        persistenceBridge.setText(JSON.stringify(data))
    }

    FileView {
        id: persistenceBridge
        path: root.chronoPersistencePath; printErrors: false
        onLoaded: {
            try {
                let p = JSON.parse(text())
                if (p.alarms) { 
                    root.alarmStore.clear()
                    for (let a of p.alarms) { a.lastFired = ""; root.alarmStore.append(a) } 
                }
                if (p.clocks) { 
                    root.worldClockStore.clear()
                    for (let c of p.clocks) root.worldClockStore.append(c) 
                }
                if (p.presets) {
                    root.presetStore.clear()
                    for (let pr of p.presets) root.presetStore.append(pr)
                }
                if (p.habits) {
                    root.habitStore.clear()
                    for (let h of p.habits) root.habitStore.append(h)
                }
                if (p.pomoTasks) {
                    root.pomoTaskStore.clear()
                    for (let pt of p.pomoTasks) root.pomoTaskStore.append(pt)
                }
                if (p.hasOwnProperty("autoFocus")) root.autoFocusMode = p.autoFocus
                if (p.pomoWork) root.pomoWorkSeconds = p.pomoWork
                if (p.pomoShort) root.pomoShortBreakSeconds = p.pomoShort
                if (p.pomoLong) root.pomoLongBreakSeconds = p.pomoLong
            } catch (e) {}
        }
    }
}
