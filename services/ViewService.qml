pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    property PanelWindow settingsWindow: null
    property PanelWindow controlPanelWindow: null
    property PanelWindow wallpaperWindow: null

    function openSettings() {
        if (settingsWindow) settingsWindow.visible = true
    }

    function toggleSettings() {
        if (settingsWindow) settingsWindow.visible = !settingsWindow.visible
    }

    function openControlPanel(page = "wifi") {
        if (controlPanelWindow) {
            controlPanelWindow.activePage = page
            controlPanelWindow.visible = true
        }
    }

    function toggleControlPanel(page = "wifi") {
        if (controlPanelWindow) {
            if (controlPanelWindow.visible && controlPanelWindow.activePage === page) {
                controlPanelWindow.visible = false
            } else {
                controlPanelWindow.activePage = page
                controlPanelWindow.visible = true
            }
        }
    }

    function openWallpaper() {
        if (wallpaperWindow) wallpaperWindow.visible = true
    }

    function toggleWallpaper() {
        if (wallpaperWindow) wallpaperWindow.visible = !wallpaperWindow.visible
    }

    function closeAll() {
        if (settingsWindow) settingsWindow.visible = false
        if (controlPanelWindow) controlPanelWindow.visible = false
        if (wallpaperWindow) wallpaperWindow.visible = false
    }

    function closeWindow(winType) {
        if (winType === "settings" && settingsWindow) settingsWindow.visible = false
        if (winType === "controlPanel" && controlPanelWindow) controlPanelWindow.visible = false
        if (winType === "wallpaper" && wallpaperWindow) wallpaperWindow.visible = false
    }
}
