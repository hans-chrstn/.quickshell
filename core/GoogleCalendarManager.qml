pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.core
import qs.shared

Singleton {
    id: root

    property bool isAvailable: {
        return !!gcalDependency.isAvailable
    }
    
    property bool isTesting: false
    property bool isManualSync: false
    
    DependencyChecker {
        id: gcalDependency
        binaryName: "gcalcli"
    }

    function getCreds() {
        let args = ""
        let clientId = String(ThemeManager.googleCalendarClientId || "").trim()
        let clientSecret = String(ThemeManager.googleCalendarClientSecret || "").trim()
        
        if (clientId !== "") {
            args += " --client-id " + clientId
        }
        
        if (clientSecret !== "") {
            args += " --client-secret " + clientSecret
        }
        
        return args
    }

    function testConnection() {
        if (!root.isAvailable) {
            OSDManager.show(
                "gcalcli not found", 
                ThemeManager.iconWifiOff
            )
            return
        }
        
        root.isTesting = true
        testProcess.command = [
            "sh", 
            "-c", 
            "gcalcli " + root.getCreds() + " list --nocolor 2>&1"
        ]
        testProcess.running = true
    }

    Process {
        id: testProcess
        
        stdout: StdioCollector {
            onStreamFinished: {
                if (!root.isTesting) {
                    return
                }
                
                root.isTesting = false
                let out = root.stripAnsi(String(text || "").trim())
                
                if (out !== "" && !out.toLowerCase().includes("error")) {
                    OSDManager.show(
                        "Calendar Linked", 
                        ThemeManager.iconCheck
                    )
                } else {
                    OSDManager.show(
                        "Link Failed", 
                        ThemeManager.iconClose
                    )
                }
            }
        }
    }

    function fetchEvents(startDate, endDate, manual = false) {
        if (!ThemeManager.googleCalendarEnabled || !root.isAvailable) {
            return
        }
        
        if (fetchProcess.running) {
            return
        }
        
        root.isManualSync = manual
        let start = Qt.formatDate(startDate, "yyyy-MM-dd")
        let end = Qt.formatDate(endDate, "yyyy-MM-dd")
        
        fetchProcess.command = [
            "sh", 
            "-c", 
            "gcalcli " + root.getCreds() + " agenda " + start + " " + end + " --nocolor --tsv --military 2>&1"
        ]
        fetchProcess.running = true
    }

    Process {
        id: fetchProcess
        
        stdout: StdioCollector {
            onStreamFinished: {
                let out = root.stripAnsi(String(text || ""))
                if (out.trim() !== "") {
                    root.parseEvents(out)
                }
            }
        }
    }

    signal eventsSynced(var googleEvents)

    function stripAnsi(str) {
        return str.replace(/[\u001b\u009b][[()#;?]*(?:[0-9]{1,4}(?:;[0-9]{0,4})*)?[0-9A-ORZcf-nqry=><]/g, "")
    }

    function parseEvents(tsvData) {
        let lines = tsvData.split("\n")
        let parsedEvents = []
        
        for (let i = 0; i < lines.length; i++) {
            let line = lines[i].trim()
            if (line === "" || line.startsWith("start_date")) {
                continue
            }
            
            let parts = line.split("\t")
            if (parts.length < 5) {
                parts = line.split(/\s{2,}/)
            }
            
            if (parts.length >= 5) {
                parsedEvents.push({
                    "date": String(parts[0]).trim(),
                    "time": String(parts[1]).trim(),
                    "title": String(parts[4]).trim(),
                    "isGoogleEvent": true,
                    "category": "personal"
                })
            }
        }
        
        root.eventsSynced(parsedEvents)
        
        if (root.isManualSync) {
            OSDManager.show(
                parsedEvents.length + " Google Events Synced", 
                ThemeManager.iconCheck
            )
            root.isManualSync = false
        }
    }

    function syncAddEvent(eventData) {
        if (!ThemeManager.googleCalendarEnabled || !root.isAvailable) {
            return
        }
        
        let when = eventData.date
        if (!eventData.allDay) {
            when += " " + eventData.time
        }
        
        let cmd = "gcalcli " + root.getCreds() + " add --title \"" + eventData.title + "\" --when \"" + when + "\" --duration 60 --noprompt"
        
        if (ThemeManager.googleCalendarAccount !== "") {
            cmd += " --calendar \"" + ThemeManager.googleCalendarAccount + "\""
        }
        
        if (eventData.allDay) {
            cmd += " --allday"
        }
        
        if (eventData.location) {
            cmd += " --where \"" + eventData.location + "\""
        }
        
        Quickshell.execDetached([
            "sh", 
            "-c", 
            cmd
        ])
    }

    function syncDeleteEvent(title, date) {
        if (!ThemeManager.googleCalendarEnabled || !root.isAvailable) {
            return
        }
        
        let cmd = "gcalcli " + root.getCreds() + " delete \"" + title + "\" --iamaexpert"
        
        Quickshell.execDetached([
            "sh", 
            "-c", 
            cmd
        ])
    }
}
