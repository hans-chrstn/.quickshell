pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    property string lastActiveScreenName: (Quickshell.screens.length > 0) ? Quickshell.screens[0].name : ""
    
    property bool dashboardTriggerHovered: false
    property bool dashboardContentHovered: false
    
    property bool _leftDashboardOpen: false
    readonly property bool leftDashboardOpen: _leftDashboardOpen

    function updateDashboardState() {
        if (dashboardTriggerHovered || dashboardContentHovered) {
            hysteresisTimer.stop()
            _leftDashboardOpen = true
        } else {
            hysteresisTimer.restart()
        }
    }

    onDashboardTriggerHoveredChanged: updateDashboardState()
    onDashboardContentHoveredChanged: updateDashboardState()

    Timer {
        id: hysteresisTimer
        interval: 300
        onTriggered: _leftDashboardOpen = false
    }

    function trackScreen(name) {
        if (name && name !== "") {
            lastActiveScreenName = name
        }
    }

    function openWindow(type) {
        let windows = root.requestedWindows
        if (!windows.includes(type)) {
            windows.push(type)
            root.requestedWindows = windows
        }
    }

    function closeWindow(type) {
        let windows = root.requestedWindows
        let index = windows.indexOf(type)
        if (index !== -1) {
            root.closingWindows.push(type)
            root.closingWindowsChanged()
            
            Qt.callLater(() => {
                let windows = root.requestedWindows
                let closing = root.closingWindows
                let i = windows.indexOf(type)
                let j = closing.indexOf(type)
                if (i !== -1) windows.splice(i, 1)
                if (j !== -1) closing.splice(j, 1)
                root.requestedWindows = windows
                root.closingWindows = closing
                root.requestedWindowsChanged()
                root.closingWindowsChanged()
            })
        }
    }

    function toggleWindow(type) {
        if (root.requestedWindows.includes(type)) {
            closeWindow(type)
        } else {
            openWindow(type)
        }
    }

    property var requestedWindows: []
    property var closingWindows: []

    function isRequested(type) { return requestedWindows.includes(type) }
    function isClosing(type) { return closingWindows.includes(type) }

    function openSettings() { openWindow("settings") }
    function toggleSettings() { toggleWindow("settings") }
    function openTaskManager() { openWindow("taskManager") }
    function toggleTaskManager() { toggleWindow("taskManager") }
    function openNotes() { openWindow("notes") }
    function toggleNotes() { toggleWindow("notes") }
    function openWallpaper() { openWindow("wallpaper") }
    function toggleWallpaper() { toggleWindow("wallpaper") }
    function openCommandPalette() { openWindow("commandPalette") }
    function toggleCommandPalette() { toggleWindow("commandPalette") }
    function closeWindowByType(type) { closeWindow(type) }
}
