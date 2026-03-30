pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    property string lastActiveScreenName: (Quickshell.screens.length > 0) ? Quickshell.screens[0].name : ""
    
    property int hoveredWorkspaceId: -1
    property bool workspacePreviewActive: false
    
    property bool indicatorHovered: false
    property bool previewHovered: false
    readonly property bool anyHovered: indicatorHovered || previewHovered
    
    function setHoveredWorkspace(id) {
        if (id !== -1) {
            root.hoveredWorkspaceId = id
            root.workspacePreviewActive = true
        }
    }

    onAnyHoveredChanged: {
        if (anyHovered) {
            hysteresisTimer.stop()
        } else {
            hysteresisTimer.restart()
        }
    }

    Timer {
        id: hysteresisTimer
        interval: 350
        onTriggered: {
            root.workspacePreviewActive = false
            root.hoveredWorkspaceId = -1
        }
    }

    property bool dashboardTriggerHovered: false
    property bool dashboardContentHovered: false
    property bool _leftDashboardOpen: false
    readonly property bool leftDashboardOpen: _leftDashboardOpen

    function updateDashboardState() {
        if (dashboardTriggerHovered || dashboardContentHovered) {
            dashboardHysteresis.stop()
            _leftDashboardOpen = true
        } else {
            dashboardHysteresis.restart()
        }
    }

    onDashboardTriggerHoveredChanged: updateDashboardState()
    onDashboardContentHoveredChanged: updateDashboardState()

    Timer {
        id: dashboardHysteresis
        interval: 300
        onTriggered: _leftDashboardOpen = false
    }

    property var activeWindows: ({})
    property var closingWindows: ({})

    function trackScreen(name) {
        if (name && name !== "") {
            lastActiveScreenName = name
        }
    }

    function openWindow(type) {
        let active = Object.assign({}, root.activeWindows)
        active[type] = true
        root.activeWindows = active
    }

    function closeWindow(type) {
        if (!root.activeWindows[type]) return
        
        let closing = Object.assign({}, root.closingWindows)
        closing[type] = true
        root.closingWindows = closing
        
        let timer = Qt.createQmlObject('import QtQuick; Timer { interval: 350; repeat: false }', root)
        timer.triggered.connect(() => {
            let active = Object.assign({}, root.activeWindows)
            let cls = Object.assign({}, root.closingWindows)
            delete active[type]
            delete cls[type]
            root.activeWindows = active
            root.closingWindows = cls
            timer.destroy()
        })
        timer.start()
    }

    function toggleWindow(type) {
        if (root.activeWindows[type]) {
            closeWindow(type)
        } else {
            openWindow(type)
        }
    }

    function isRequested(type) { return !!root.activeWindows[type] }
    function isClosing(type) { return !!root.closingWindows[type] }

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
    function openNetwork() { openWindow("network") }
    function toggleNetwork() { toggleWindow("network") }
    function openBluetooth() { openWindow("bluetooth") }
    function toggleBluetooth() { toggleWindow("bluetooth") }
    function closeWindowByType(type) { closeWindow(type) }
}
