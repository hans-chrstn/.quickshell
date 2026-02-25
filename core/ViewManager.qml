pragma Singleton
import QtQuick
import Quickshell
import qs.ui.screens

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

    property bool isSettingsClosing: false
    property bool isControlPanelClosing: false
    property bool isWallpaperClosing: false

    function openSettings() {
        root.isSettingsClosing = false
        settingsWindow.visible = true
    }

    function toggleSettings() {
        if (settingsWindow.visible) {
            closeWindowByType("settings")
        } else {
            openSettings()
        }
    }

    function openControlPanel(page = "wifi") {
        root.isControlPanelClosing = false
        controlPanelWindow.activePage = page
        controlPanelWindow.visible = true
    }

    function toggleControlPanel(page = "wifi") {
        if (controlPanelWindow.visible && controlPanelWindow.activePage === page) {
            closeWindowByType("controlPanel")
        } else {
            openControlPanel(page)
        }
    }

    function openWallpaper() {
        root.isWallpaperClosing = false
        wallpaperWindow.visible = true
    }

    function toggleWallpaper() {
        if (wallpaperWindow.visible) {
            closeWindowByType("wallpaper")
        } else {
            openWallpaper()
        }
    }

    function closeWindowByType(windowType) {
        if (windowType === "settings") {
            root.isSettingsClosing = true
            settingsCloseTimer.restart()
        } else if (windowType === "controlPanel") {
            root.isControlPanelClosing = true
            controlPanelCloseTimer.restart()
        } else if (windowType === "wallpaper") {
            root.isWallpaperClosing = true
            wallpaperCloseTimer.restart()
        }
    }

    Timer { 
        id: settingsCloseTimer
        interval: 350
        onTriggered: { 
            settingsWindow.visible = false
            root.isSettingsClosing = false 
        } 
    }

    Timer { 
        id: controlPanelCloseTimer
        interval: 350
        onTriggered: { 
            controlPanelWindow.visible = false
            root.isControlPanelClosing = false 
        } 
    }

    Timer { 
        id: wallpaperCloseTimer
        interval: 350
        onTriggered: { 
            wallpaperWindow.visible = false
            root.isWallpaperClosing = false 
        } 
    }
}
