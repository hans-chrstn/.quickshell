pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    property PanelWindow settingsWindow: null
    property PanelWindow controlPanelWindow: null
    property PanelWindow wallpaperWindow: null

    property bool closingSettings: false
    property bool closingControlPanel: false
    property bool closingWallpaper: false

    function openSettings() {
        if (settingsWindow) {
            root.closingSettings = false
            settingsWindow.visible = true
        }
    }

    function toggleSettings() {
        if (settingsWindow && settingsWindow.visible) closeWindow("settings")
        else openSettings()
    }

    function openControlPanel(page = "wifi") {
        if (controlPanelWindow) {
            root.closingControlPanel = false
            controlPanelWindow.activePage = page
            controlPanelWindow.visible = true
        }
    }

    function toggleControlPanel(page = "wifi") {
        if (controlPanelWindow && controlPanelWindow.visible && controlPanelWindow.activePage === page) {
            closeWindow("controlPanel")
        } else {
            openControlPanel(page)
        }
    }

    function openWallpaper() {
        if (wallpaperWindow) {
            root.closingWallpaper = false
            wallpaperWindow.visible = true
        }
    }

    function toggleWallpaper() {
        if (wallpaperWindow && wallpaperWindow.visible) closeWindow("wallpaper")
        else openWallpaper()
    }

    function closeWindow(winType) {
        if (winType === "settings" && settingsWindow) {
            root.closingSettings = true
            Qt.callLater(() => { closeTimerSettings.restart() })
        }
        if (winType === "controlPanel" && controlPanelWindow) {
            root.closingControlPanel = true
            Qt.callLater(() => { closeTimerControlPanel.restart() })
        }
        if (winType === "wallpaper" && wallpaperWindow) {
            root.closingWallpaper = true
            Qt.callLater(() => { closeTimerWallpaper.restart() })
        }
    }

    Timer { id: closeTimerSettings; interval: 350; onTriggered: { if (settingsWindow) settingsWindow.visible = false; root.closingSettings = false } }
    Timer { id: closeTimerControlPanel; interval: 350; onTriggered: { if (controlPanelWindow) controlPanelWindow.visible = false; root.closingControlPanel = false } }
    Timer { id: closeTimerWallpaper; interval: 350; onTriggered: { if (wallpaperWindow) wallpaperWindow.visible = false; root.closingWallpaper = false } }
}
