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

    readonly property ListModel filteredModel: ListModel {}

    readonly property string cachePath: Quickshell.cachePath("calendar_events.json")
    readonly property string remoteCachePath: Quickshell.cachePath("google_events_cache.json")
    property bool isReady: false

    function addEvent(eventData) {
        let list = [...root.events]
        eventData.id = Date.now().toString()
        eventData.isGoogleEvent = false
        list.push(eventData)
        root.events = list
        save()
        root.updateFilteredModel()

        if (ThemeManager.googleCalendarEnabled) {
            GoogleCalendarManager.syncAddEvent(eventData)
            OSDManager.show("Syncing to Google...", ThemeManager.iconCheck)
            postAddSyncTimer.restart()
        }
    }

    function syncLocalToGoogle() {
        if (!ThemeManager.googleCalendarEnabled) return
        
        console.log("Shell: Syncing all existing local events to Google...")
        for (let i = 0; i < root.events.length; i++) {
            GoogleCalendarManager.syncAddEvent(root.events[i])
        }
        
        OSDManager.show("Local Events Synced to Google", ThemeManager.iconCheck)
        postAddSyncTimer.restart()
    }

    function deleteEvent(id, isGoogle = false, title = "", date = "") {
        deleteLocalEvent(id)

        if (ThemeManager.googleCalendarEnabled) {
            GoogleCalendarManager.syncDeleteEvent(title, date)
            
            let newSynced = [...root.syncedEvents]
            let idx = newSynced.findIndex(e => e.title === title && e.date === date)
            if (idx !== -1) {
                newSynced.splice(idx, 1)
                root.syncedEvents = newSynced
                saveRemoteCache()
            }
            root.updateFilteredModel()
        }
    }

    function deleteLocalEvent(id) {
        let list = [...root.events]
        let idx = list.findIndex(e => e.id === id)
        if (idx !== -1) {
            list.splice(idx, 1)
            root.events = list
            save()
            root.updateFilteredModel()
        }
    }

    function updateFilteredModel() {
        let searchDate = Qt.formatDate(root.selectedDate, "yyyy-MM-dd")
        root.filteredModel.clear()
        
        let localItems = root.events.filter(e => e.date === searchDate)
        for (let i = 0; i < localItems.length; i++) {
            root.filteredModel.append(localItems[i])
        }

        let remoteItems = root.syncedEvents.filter(e => e.date === searchDate)
        for (let i = 0; i < remoteItems.length; i++) {
            let existsLocally = false
            for (let j = 0; j < root.filteredModel.count; j++) {
                let item = root.filteredModel.get(j)
                if (item.title === remoteItems[i].title && item.time === remoteItems[i].time) {
                    existsLocally = true
                    break
                }
            }
            if (!existsLocally) root.filteredModel.append(remoteItems[i])
        }
    }

    function triggerSync(manual = true) {
        if (!ThemeManager.googleCalendarEnabled) return
        
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
        onTriggered: root.triggerSync(false)
    }

    Timer {
        interval: 30 * 60 * 1000
        running: ThemeManager.googleCalendarEnabled
        repeat: true
        onTriggered: root.triggerSync(false)
    }

    Connections {
        target: GoogleCalendarManager
        function onEventsSynced(googleEvents) {
            let newDataStr = JSON.stringify(googleEvents)
            let oldDataStr = JSON.stringify(root.syncedEvents)
            if (newDataStr === oldDataStr) return
            root.syncedEvents = googleEvents
            saveRemoteCache()
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
                saveRemoteCache()
                root.updateFilteredModel()
            }
        }
    }

    onSelectedDateChanged: updateFilteredModel()

    function save() {
        if (!isReady) return
        eventsFile.setText(JSON.stringify(root.events, null, 4))
    }

    function saveRemoteCache() {
        remoteCacheFile.setText(JSON.stringify(root.syncedEvents))
    }

    function hasEventsOnDate(d) {
        let searchDate = Qt.formatDate(d, "yyyy-MM-dd")
        let localHas = root.events.some(e => e.date === searchDate)
        let remoteHas = root.syncedEvents.some(e => e.date === searchDate)
        return localHas || remoteHas
    }

    FileView {
        id: eventsFile
        path: root.cachePath
        printErrors: false
        onLoaded: {
            try {
                let content = text()
                if (content && content.trim() !== "") {
                    let parsed = JSON.parse(content)
                    if (Array.isArray(parsed)) root.events = parsed
                }
            } catch(e) {}
            root.isReady = true
            root.updateFilteredModel()
        }
    }

    FileView {
        id: remoteCacheFile
        path: root.remoteCachePath
        printErrors: false
        onLoaded: {
            try {
                let content = text()
                if (content && content.trim() !== "") {
                    let parsed = JSON.parse(content)
                    if (Array.isArray(parsed)) {
                        root.syncedEvents = parsed
                        if (ThemeManager.googleCalendarEnabled) root.updateFilteredModel()
                    }
                }
            } catch(e) {}
        }
    }
}
