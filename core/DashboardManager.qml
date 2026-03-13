pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    property bool active: false
    property bool realActive: false
    property int currentPage: 0
    property bool suppressDismiss: false
    
    readonly property var pages: [
        { "id": "calendar", "title": "Schedule", "icon": "󰥔" },
        { "id": "timer", "title": "Timers & Alarms", "icon": "󰔛" },
        { "id": "mixer", "title": "Audio Mixer", "icon": "󰕾" },
        { "id": "clipboard", "title": "Clipboard", "icon": "󰅍" },
        { "id": "notes", "title": "Scratchpad", "icon": "󰠮" }
    ]

    property bool _lockTrigger: false
    property bool _startupLock: true
    
    Timer {
        id: lockTimer
        interval: 500
        onTriggered: root._lockTrigger = false
    }

    Timer {
        id: startupTimer
        interval: 1000
        running: true
        onTriggered: root._startupLock = false
    }

    Timer {
        id: dismissTimer
        interval: 500
        onTriggered: root.close()
    }

    function cancelDismiss() {
        dismissTimer.stop()
    }

    function requestDismiss() {
        if (!root.suppressDismiss) {
            dismissTimer.restart()
        }
    }

    function toggle() {
        if (root._lockTrigger || root._startupLock) return
        
        if (root.active) {
            root.active = false
        } else {
            root.realActive = true
            root.active = true
        }
    }

    function open() {
        if (root._lockTrigger || root._startupLock) return
        root.realActive = true
        root.active = true
    }

    function close() {
        root.active = false
    }

    function finalizeClose() {
        Qt.callLater(() => {
            root.realActive = false
            root._lockTrigger = true
            lockTimer.start()
        })
    }
}
