pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.core

Singleton {
    id: root

    property date selectedDate: new Date()
    property var events: []
    property var syncedEvents: []
    
    readonly property var categories: [
        { id: "work", label: "Work", icon: "󰓗", color: "#47A8FF" },
        { id: "personal", label: "Personal", icon: "󰭹", color: "#FF47A8" },
        { id: "fitness", label: "Fitness", icon: "󰗖", color: "#47FFBC" },
        { id: "urgent", label: "Urgent", icon: "󰗖", color: "#FF4747" }
    ]

    readonly property ListModel filteredModel: ListModel {
    }

    readonly property string cachePath: {
        return Quickshell.cachePath("calendar_events.json")
    }
    
    readonly property string remoteCachePath: {
        return Quickshell.cachePath("google_events_cache.json")
    }
    
    property bool isReady: false

    function addEvent(eventData) {
        let list = [...root.events]
        eventData.id = Date.now().toString()
        eventData.isGoogleEvent = false
        list.push(eventData)
        root.events = list
        root.save()
        root.updateFilteredModel()

        if (ThemeManager.googleCalendarEnabled) {
            GoogleCalendarManager.syncAddEvent(eventData)
            OSDManager.show(
                "Syncing to Google...", 
                ThemeManager.iconCheck
            )
            postAddSyncTimer.restart()
        }
    }

    function syncLocalToGoogle() {
        if (!ThemeManager.googleCalendarEnabled) {
            return
        }
        
        for (let i = 0; i < root.events.length; i++) {
            GoogleCalendarManager.syncAddEvent(root.events[i])
        }
        
        OSDManager.show(
            "Pushing Local to Cloud", 
            ThemeManager.iconCheck
        )
        postAddSyncTimer.restart()
    }

    function deleteEvent(id, isGoogle = false, title = "", date = "") {
        if (ThemeManager.googleCalendarEnabled) {
            GoogleCalendarManager.syncDeleteEvent(title, date)
            
            let newSynced = [...root.syncedEvents]
            let sIdx = newSynced.findIndex(e => e.title === title && e.date === date)
            if (sIdx !== -1) {
                newSynced.splice(sIdx, 1)
                root.syncedEvents = newSynced
                root.saveRemoteCache()
            }
        }

        let list = [...root.events]
        let idx = list.findIndex(e => {
            if (id && e.id === id) {
                return true
            }
            if (title !== "" && date !== "" && e.title === title && e.date === date) {
                return true
            }
            return false
        })
        
        if (idx !== -1) {
            list.splice(idx, 1)
            root.events = list
            root.save()
        }
        
        root.updateFilteredModel()
    }

    function updateFilteredModel() {
        let searchDate = Qt.formatDate(root.selectedDate, "yyyy-MM-dd")
        root.filteredModel.clear()
        
        if (ThemeManager.googleCalendarEnabled) {
            let remoteItems = root.syncedEvents.filter(e => e.date === searchDate)
            for (let i = 0; i < remoteItems.length; i++) {
                root.filteredModel.append(remoteItems[i])
            }
        } else {
            let localItems = root.events.filter(e => e.date === searchDate)
            for (let i = 0; i < localItems.length; i++) {
                root.filteredModel.append(localItems[i])
            }
        }
    }

    function triggerSync(manual = true) {
        if (!ThemeManager.googleCalendarEnabled) {
            return
        }
        
        let start = new Date(root.selectedDate)
        start.setDate(start.getDate() - 30)
        let end = new Date(root.selectedDate)
        end.setDate(end.getDate() + 60)
        GoogleCalendarManager.fetchEvents(start, end, manual)
    }

    Timer {
        id: postAddSyncTimer
        interval: 3000
        repeat: false
        onTriggered: {
            root.triggerSync(false)
        }
    }

    Timer {
        interval: 30 * 60 * 1000
        running: {
            return !!ThemeManager.googleCalendarEnabled
        }
        repeat: true
        onTriggered: {
            root.triggerSync(false)
        }
    }

    Connections {
        target: GoogleCalendarManager
        function onEventsSynced(googleEvents) {
            root.syncedEvents = googleEvents
            root.saveRemoteCache()
            root.updateFilteredModel()
        }
    }

    Connections {
        target: ThemeManager
        function onGoogleCalendarEnabledChanged() {
            if (ThemeManager.googleCalendarEnabled) {
                root.syncLocalToGoogle()
            } else {
                root.syncedEvents = []
                root.saveRemoteCache()
                root.updateFilteredModel()
            }
        }
    }

    onSelectedDateChanged: {
        root.updateFilteredModel()
    }

    function save() {
        if (!root.isReady) {
            return
        }
        eventsFile.setText(
            JSON.stringify(root.events, null, 4)
        )
    }

    function saveRemoteCache() {
        remoteCacheFile.setText(
            JSON.stringify(root.syncedEvents)
        )
    }

    function hasEventsOnDate(d) {
        let searchDate = Qt.formatDate(d, "yyyy-MM-dd")
        if (ThemeManager.googleCalendarEnabled) {
            return root.syncedEvents.some(e => e.date === searchDate)
        }
        return root.events.some(e => e.date === searchDate)
    }

    FileView {
        id: eventsFile
        path: root.cachePath
        printErrors: false
        
        onLoaded: {
            if (eventsFile.status === FileView.Ready) {
                try {
                    let content = text()
                    if (content && content.trim() !== "") {
                        let parsed = JSON.parse(content)
                        if (Array.isArray(parsed)) {
                            root.events = parsed
                        }
                    }
                } catch(e) {
                    console.error("CalendarManager: Parse Local Failed")
                }
            }
            
            root.isReady = true
            root.updateFilteredModel()
        }
    }

    FileView {
        id: remoteCacheFile
        path: root.remoteCachePath
        printErrors: false
        
        onLoaded: {
            if (remoteCacheFile.status === FileView.Ready) {
                try {
                    let content = text()
                    if (content && content.trim() !== "") {
                        let parsed = JSON.parse(content)
                        if (Array.isArray(parsed)) {
                            root.syncedEvents = parsed
                            if (ThemeManager.googleCalendarEnabled) {
                                root.updateFilteredModel()
                            }
                        }
                    }
                } catch(e) {
                    console.error("CalendarManager: Parse Remote Failed")
                }
            }
        }
    }

    Component.onCompleted: {
        Qt.callLater(() => {
            if (!root.isReady) {
                root.isReady = true
                root.updateFilteredModel()
            }
        })
    }
}
