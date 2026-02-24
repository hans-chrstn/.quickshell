pragma Singleton
import QtQuick
import Quickshell
import qs.modules.windows

Singleton {
    id: root

    readonly property SettingsWindow settingsWindow: SettingsWindow {
        visible: false
        screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    }

    readonly property WallpaperWindow wallpaperWindow: WallpaperWindow {
        visible: false
        screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    }

    readonly property ControlPanelWindow controlPanelWindow: ControlPanelWindow {
        visible: false
        screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    }

    property bool closingSettings: false
    property bool closingControlPanel: false
    property bool closingWallpaper: false

    function openSettings() {
        root.closingSettings = false
        settingsWindow.visible = true
    }

    function toggleSettings() {
        if (settingsWindow.visible) closeWindow("settings")
        else openSettings()
    }

    function openControlPanel(page = "wifi") {
        root.closingControlPanel = false
        controlPanelWindow.activePage = page
        controlPanelWindow.visible = true
    }

    function toggleControlPanel(page = "wifi") {
        if (controlPanelWindow.visible && controlPanelWindow.activePage === page) {
            closeWindow("controlPanel")
        } else {
            openControlPanel(page)
        }
    }

    function openWallpaper() {
        root.closingWallpaper = false
        wallpaperWindow.visible = true
    }

    function toggleWallpaper() {
        if (wallpaperWindow.visible) closeWindow("wallpaper")
        else openWallpaper()
    }

    function closeWindow(winType) {
        if (winType === "settings") {
            root.closingSettings = true
            closeTimerSettings.restart()
        }
        if (winType === "controlPanel") {
            root.closingControlPanel = true
            closeTimerControlPanel.restart()
        }
        if (winType === "wallpaper") {
            root.closingWallpaper = true
            closeTimerWallpaper.restart()
        }
    }

    Timer { id: closeTimerSettings; interval: 350; onTriggered: { settingsWindow.visible = false; root.closingSettings = false } }
    Timer { id: closeTimerControlPanel; interval: 350; onTriggered: { controlPanelWindow.visible = false; root.closingControlPanel = false } }
    Timer { id: closeTimerWallpaper; interval: 350; onTriggered: { wallpaperWindow.visible = false; root.closingWallpaper = false } }
}
