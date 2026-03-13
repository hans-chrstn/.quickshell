pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.core
import qs.shared

Singleton {
    id: root

    property bool isAvailable: gcalDependency.isAvailable
    property bool isTesting: false
    property bool isManualSync: false
    
    readonly property string tempOutPath: Quickshell.cachePath("gcal_sync_tmp.txt")

    DependencyChecker {
        id: gcalDependency
        binaryName: "gcalcli"
    }

    function getCreds() {
        let args = ""
        if (ThemeManager.googleCalendarClientId && ThemeManager.googleCalendarClientId.trim() !== "") {
            args += " --client-id " + ThemeManager.googleCalendarClientId.trim()
        }
        if (ThemeManager.googleCalendarClientSecret && ThemeManager.googleCalendarClientSecret.trim() !== "") {
            args += " --client-secret " + ThemeManager.googleCalendarClientSecret.trim()
        }
        return args
    }

    function testConnection() {
        if (!isAvailable) {
            OSDManager.show("gcalcli not found", ThemeManager.iconWifiOff)
            return
        }
        
        root.isTesting = true
        let cmd = "gcalcli " + getCreds() + " list --nocolor > " + root.tempOutPath + " 2>&1"
        testProcess.command = ["sh", "-c", cmd]
        testProcess.running = true
    }

    Process {
        id: testProcess
        onExited: (code) => {
            if (!root.isTesting) return
            root.isTesting = false
            testFileReader.reload()
        }
    }

    FileView {
        id: testFileReader
        path: root.tempOutPath
        onLoaded: {
            if (!root.isTesting && !root.isManualSync) return
            let out = stripAnsi(text().trim())
            if (out !== "" && !out.toLowerCase().includes("error")) {
                if (root.isTesting) OSDManager.show("Calendar Linked", ThemeManager.iconCheck)
            } else if (root.isTesting) {
                OSDManager.show("Link Failed", ThemeManager.iconClose)
            }
        }
    }

    function fetchEvents(startDate, endDate, manual = false) {
        if (!ThemeManager.googleCalendarEnabled || !isAvailable) return
        
        root.isManualSync = manual
        let start = Qt.formatDate(startDate, "yyyy-MM-dd")
        let end = Qt.formatDate(endDate, "yyyy-MM-dd")
        
        if (fetchProcess.running) return; 
        
        let cmd = "gcalcli " + getCreds() + " agenda " + start + " " + end + " --nocolor --tsv --military > " + root.tempOutPath + " 2>&1"
        fetchProcess.command = ["sh", "-c", cmd]
        fetchProcess.running = true
    }

    Process {
        id: fetchProcess
        onExited: (code) => {
            fetchFileReader.reload()
        }
    }

    FileView {
        id: fetchFileReader
        path: root.tempOutPath
        onLoaded: {
            let out = stripAnsi(text())
            if (out.trim() !== "") parseEvents(out)
        }
    }

    signal eventsSynced(var googleEvents)

    function stripAnsi(str) {
        return str.replace(/[\u001b\u009b][[()#;?]*(?:[0-9]{1,4}(?:;[0-9]{0,4})*)?[0-9A-ORZcf-nqry=><]/g, "");
    }

    function parseEvents(tsvData) {
        let lines = tsvData.split("\n")
        let parsedEvents = []
        for (let i = 0; i < lines.length; i++) {
            let line = lines[i].trim()
            if (line === "" || line.startsWith("start_date")) continue
            let parts = line.split("\t")
            if (parts.length < 5) parts = line.split(/\s{2,}/)
            if (parts.length >= 5) {
                parsedEvents.push({
                    date: parts[0].trim(),
                    time: parts[1].trim(),
                    title: parts[4].trim(),
                    isGoogleEvent: true,
                    category: "personal"
                })
            }
        }
        
        root.eventsSynced(parsedEvents)
        
        if (root.isManualSync) {
            OSDManager.show(parsedEvents.length + " Google Events Synced", ThemeManager.iconCheck)
            root.isManualSync = false
        }
    }

    function syncAddEvent(eventData) {
        if (!ThemeManager.googleCalendarEnabled || !isAvailable) return
        let when = eventData.date
        if (!eventData.allDay) when += " " + eventData.time
        let cmd = "gcalcli " + getCreds() + " add --title \"" + eventData.title + "\" --when \"" + when + "\" --duration 60 --noprompt"
        if (ThemeManager.googleCalendarAccount !== "") cmd += " --calendar \"" + ThemeManager.googleCalendarAccount + "\""
        if (eventData.allDay) cmd += " --allday"
        if (eventData.location) cmd += " --where \"" + eventData.location + "\""
        Quickshell.execDetached(["sh", "-c", cmd])
    }

    function syncDeleteEvent(title, date) {
        if (!ThemeManager.googleCalendarEnabled || !isAvailable) return
        let cmd = "gcalcli " + getCreds() + " delete \"" + title + "\" --iamaexpert"
        Quickshell.execDetached(["sh", "-c", cmd])
    }
}
