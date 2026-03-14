import QtQuick
import Quickshell
import Quickshell.Io
import qs.core

Item {
    id: root

    property int remainingSeconds: 0
    property bool running: false
    property string timerMode: "timer"
    property int lastInitialSeconds: 0
    
    property string pomoState: "work"
    property int pomoCount: 0
    
    readonly property ListModel alarms: ListModel {}
    readonly property string alarmsCachePath: Quickshell.cachePath("alarms_v2.json")

    signal timerFinished()
    signal alarmTriggered(string title)

    function startTimer(seconds) {
        root.timerMode = "timer"
        root.remainingSeconds = seconds
        root.lastInitialSeconds = seconds
        root.running = true
        OSDManager.show("Timer Started", ThemeManager.iconClock)
    }

    function addTime(seconds) {
        root.remainingSeconds += seconds
        if (root.remainingSeconds < 0) root.remainingSeconds = 0
        if (!root.running && root.remainingSeconds > 0) root.running = true
    }

    function togglePause() {
        if (root.remainingSeconds > 0) {
            root.running = !root.running
        }
    }

    function resetTimer() {
        root.running = false
        root.remainingSeconds = 0
        root.timerMode = "timer"
    }

    function revertTimer() {
        root.remainingSeconds = root.lastInitialSeconds
        root.running = false
    }

    function startPomodoro() {
        root.timerMode = "pomodoro"
        root.pomoState = "work"
        root.pomoCount = 0
        root.remainingSeconds = 25 * 60
        root.running = true
        OSDManager.show("Pomodoro: Work Session", ThemeManager.iconClock)
    }

    function _nextPomoStep() {
        if (root.pomoState === "work") {
            root.pomoCount++
            if (root.pomoCount % 4 === 0) {
                root.pomoState = "longBreak"
                root.remainingSeconds = 15 * 60
            } else {
                root.pomoState = "shortBreak"
                root.remainingSeconds = 5 * 60
            }
            OSDManager.show("Pomodoro: Break Time", ThemeManager.iconClock)
        } else {
            root.pomoState = "work"
            root.remainingSeconds = 25 * 60
            OSDManager.show("Pomodoro: Back to Work", ThemeManager.iconClock)
        }
        root.running = true
    }

    function addAlarm(time, title) {
        root.alarms.append({
            "time": time,
            "title": title || "Alarm",
            "enabled": true,
            "_lastTriggered": ""
        })
        saveAlarms()
        OSDManager.show("Alarm Set: " + time, ThemeManager.iconCheck)
    }

    function deleteAlarm(index) {
        if (index >= 0 && index < root.alarms.count) {
            root.alarms.remove(index)
            saveAlarms()
        }
    }

    function toggleAlarm(index) {
        if (index >= 0 && index < root.alarms.count) {
            let item = root.alarms.get(index)
            root.alarms.setProperty(index, "enabled", !item.enabled)
            saveAlarms()
        }
    }

    function formatTime(totalSeconds) {
        let h = Math.floor(totalSeconds / 3600)
        let m = Math.floor((totalSeconds % 3600) / 60)
        let s = totalSeconds % 60
        
        if (h > 0) {
            return h.toString().padStart(2, '0') + ":" + m.toString().padStart(2, '0') + ":" + s.toString().padStart(2, '0')
        }
        return m.toString().padStart(2, '0') + ":" + s.toString().padStart(2, '0')
    }

    Timer {
        id: secondTimer
        interval: 1000
        running: root.running
        repeat: true
        onTriggered: {
            if (root.remainingSeconds > 0) {
                root.remainingSeconds--
            } else {
                root.running = false
                if (root.timerMode === "pomodoro") {
                    root._nextPomoStep()
                } else {
                    SoundManager.playSuccess()
                    OSDManager.show("Timer Finished!", ThemeManager.iconClock)
                    root.timerFinished()
                }
            }
        }
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: {
            let now = new Date()
            let current = now.getHours().toString().padStart(2, '0') + ":" + now.getMinutes().toString().padStart(2, '0')
            
            for (let i = 0; i < root.alarms.count; i++) {
                let alarm = root.alarms.get(i)
                if (alarm.enabled && alarm.time === current) {
                    if (alarm._lastTriggered !== current) {
                        root.alarmTriggered(alarm.title)
                        OSDManager.show("ALARM: " + alarm.title, ThemeManager.iconClock)
                        SoundManager.playSuccess()
                        root.alarms.setProperty(i, "_lastTriggered", current)
                    }
                }
            }
        }
    }

    function saveAlarms() {
        let data = []
        for (let i = 0; i < root.alarms.count; i++) {
            let a = root.alarms.get(i)
            data.push({ time: a.time, title: a.title, enabled: a.enabled })
        }
        alarmsFile.setText(JSON.stringify(data))
    }

    FileView {
        id: alarmsFile
        path: root.alarmsCachePath
        printErrors: false
        onLoaded: {
            try {
                let content = text()
                if (content && content.trim() !== "") {
                    let parsed = JSON.parse(content)
                    root.alarms.clear()
                    for (let i = 0; i < parsed.length; i++) {
                        let item = parsed[i]
                        item._lastTriggered = ""
                        root.alarms.append(item)
                    }
                }
            } catch(e) {}
        }
    }
}
