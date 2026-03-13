pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.core

Singleton {
    id: root

    property int remainingSeconds: 0
    property int totalSessionSeconds: 0
    property bool running: false
    property string mode: "timer"
    
    readonly property ListModel alarms: ListModel {}
    readonly property string alarmsCachePath: Quickshell.cachePath("alarms.json")

    signal finished()

    function startTimer(minutes) {
        root.mode = "timer"
        root.totalSessionSeconds = minutes * 60
        root.remainingSeconds = root.totalSessionSeconds
        root.running = true
        OSDManager.show("Timer Started", ThemeManager.iconClock)
    }

    function togglePause() {
        if (root.remainingSeconds > 0) {
            root.running = !root.running
        }
    }

    function reset() {
        root.running = false
        root.remainingSeconds = 0
        root.totalSessionSeconds = 0
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

    function formatTime(seconds) {
        let m = Math.floor(seconds / 60)
        let s = seconds % 60
        return m.toString().padStart(2, '0') + ":" + s.toString().padStart(2, '0')
    }

    Timer {
        id: mainTimer
        interval: 1000
        running: root.running
        repeat: true
        onTriggered: {
            if (root.remainingSeconds > 0) {
                root.remainingSeconds--
            } else {
                root.running = false
                root.handleFinish()
            }
        }
    }

    function handleFinish() {
        SoundManager.playSuccess()
        OSDManager.show("Timer Finished!", ThemeManager.iconClock)
        root.finished()
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
