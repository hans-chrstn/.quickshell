pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.core

Singleton {
    id: root

    property date selectedDate: new Date()
    property var events: []
    
    readonly property var categories: [
        { id: "work", label: "Work", icon: "󰓗", color: "#47A8FF" },
        { id: "personal", label: "Personal", icon: "󰭹", color: "#FF47A8" },
        { id: "fitness", label: "Fitness", icon: "󰗖", color: "#47FFBC" },
        { id: "urgent", label: "Urgent", icon: "󰗖", color: "#FF4747" }
    ]

    readonly property ListModel filteredModel: ListModel {}

    readonly property string cachePath: Quickshell.cachePath("calendar_events.json")
    property bool isReady: false

    function addEvent(eventData) {
        let list = [...root.events]
        eventData.id = Date.now().toString()
        list.push(eventData)
        root.events = list
        save()
        
        let searchDate = Qt.formatDate(root.selectedDate, "yyyy-MM-dd")
        if (eventData.date === searchDate) {
            root.filteredModel.append(eventData)
        }
    }

    function deleteEvent(id) {
        let list = [...root.events]
        let idx = list.findIndex(e => e.id === id)
        if (idx !== -1) {
            list.splice(idx, 1)
            root.events = list
            save()
            
            for (let i = 0; i < root.filteredModel.count; i++) {
                if (root.filteredModel.get(i).id === id) {
                    root.filteredModel.remove(i)
                    break
                }
            }
        }
    }

    function updateFilteredModel() {
        root.filteredModel.clear()
        let items = getEventsForDate(root.selectedDate)
        for (let i = 0; i < items.length; i++) {
            root.filteredModel.append(items[i])
        }
    }

    onSelectedDateChanged: updateFilteredModel()

    function save() {
        if (!isReady) return
        eventsFile.setText(JSON.stringify(root.events, null, 4))
    }

    function getEventsForDate(d) {
        let searchDate = Qt.formatDate(d, "yyyy-MM-dd")
        return root.events.filter(e => e.date === searchDate)
    }

    function hasEventsOnDate(d) {
        let searchDate = Qt.formatDate(d, "yyyy-MM-dd")
        return root.events.some(e => e.date === searchDate)
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
                    if (Array.isArray(parsed)) {
                        root.events = parsed
                    }
                }
            } catch(e) {}
            root.isReady = true
            root.updateFilteredModel()
        }
    }
}
