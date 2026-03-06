pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    property string lastActiveScreenName: (Quickshell.screens.length > 0) ? Quickshell.screens[0].name : ""

    function trackScreen(name) {
        if (name && name !== "") {
            lastActiveScreenName = name
        }
    }

    property var activeWindows: ({})
    property var closingWindows: ({})

    readonly property var windowConfig: ({
        "settings": { type: "settings", manager: null },
        "wallpaper": { type: "wallpaper", manager: WallpaperManager },
        "network": { type: "network", manager: null },
        "bluetooth": { type: "bluetooth", manager: null },
        "taskManager": { type: "taskManager", manager: ProcessManager },
        "notes": { type: "notes", manager: NotesManager },
        "commandPalette": { type: "commandPalette", manager: CommandPaletteManager }
    })

    signal windowOpening(string window)
    signal windowClosing(string window)

    function isRequested(window) {
        return !!activeWindows[window]
    }

    function isClosing(window) {
        return !!closingWindows[window]
    }

    function openWindow(window) {
        let config = windowConfig[window]
        if (!config) return

        let newClosing = Object.assign({}, closingWindows)
        delete newClosing[window]
        closingWindows = newClosing

        let newActive = Object.assign({}, activeWindows)
        newActive[window] = true
        activeWindows = newActive

        if (config.manager && config.manager.open) {
            config.manager.open()
        }

        root.windowOpening(window)
    }

    function closeWindow(window) {
        let config = windowConfig[window]
        if (!config || !activeWindows[window]) return

        let newClosing = Object.assign({}, closingWindows)
        newClosing[window] = true
        closingWindows = newClosing

        if (config.manager && config.manager.close) {
            config.manager.close()
        }

        root.windowClosing(window)
        
        let closeTimer = Qt.createQmlObject('import QtQuick; Timer { interval: 350; onTriggered: { root._finalizeClose("' + window + '"); destroy(); } }', root)
        closeTimer.start()
    }

    function toggleWindow(window) {
        if (isRequested(window) && !isClosing(window)) {
            closeWindow(window)
        } else {
            openWindow(window)
        }
    }

    function _finalizeClose(window) {
        let newActive = Object.assign({}, activeWindows)
        delete newActive[window]
        activeWindows = newActive

        let newClosing = Object.assign({}, closingWindows)
        delete newClosing[window]
        closingWindows = newClosing
    }

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
