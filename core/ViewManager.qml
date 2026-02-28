pragma Singleton
import QtQuick
import Quickshell
import qs.ui.screens

Singleton {
    id: root

    readonly property var primaryScreen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null

    property bool settingsRequested: false
    property bool wallpaperRequested: false
    property bool controlPanelRequested: false
    property bool taskManagerRequested: false
    property bool notesRequested: false

    LazyLoader { 
        id: settingsLdr
        activeAsync: true 
        SettingsWindow { 
            visible: root.settingsRequested && !root.isSettingsClosing
            screen: root.primaryScreen 
        } 
    }
    
    LazyLoader { 
        id: wallpaperLdr
        activeAsync: true 
        WallpaperWindow { 
            visible: root.wallpaperRequested && !root.isWallpaperClosing
            screen: root.primaryScreen 
        } 
    }
    
    LazyLoader { 
        id: controlPanelLdr
        activeAsync: true 
        ControlPanelWindow { 
            visible: root.controlPanelRequested && !root.isControlPanelClosing
            screen: root.primaryScreen 
        } 
    }
    
    LazyLoader { 
        id: taskManagerLdr
        activeAsync: true 
        TaskManagerWindow { 
            visible: root.taskManagerRequested && !root.isTaskManagerClosing
            screen: root.primaryScreen 
        } 
    }

    LazyLoader { 
        id: notesLdr
        activeAsync: true 
        NotesWindow { 
            visible: root.notesRequested && !root.isNotesClosing
            screen: root.primaryScreen 
        } 
    }

    property bool isSettingsClosing: false
    property bool isControlPanelClosing: false
    property bool isWallpaperClosing: false
    property bool isTaskManagerClosing: false
    property bool isNotesClosing: false

    function openSettings() {
        root.isSettingsClosing = false
        root.settingsRequested = true
    }

    function toggleSettings() {
        if (root.settingsRequested) {
            closeWindowByType("settings")
        } else {
            openSettings()
        }
    }

    function openControlPanel(page = "wifi") {
        root.isControlPanelClosing = false
        if (controlPanelLdr.item) {
            controlPanelLdr.item.activePage = page
        }
        root.controlPanelRequested = true
    }

    function toggleControlPanel(page = "wifi") {
        if (root.controlPanelRequested && controlPanelLdr.item && controlPanelLdr.item.activePage === page) {
            closeWindowByType("controlPanel")
        } else {
            openControlPanel(page)
        }
    }

    function openTaskManager() {
        root.isTaskManagerClosing = false
        root.taskManagerRequested = true
    }

    function toggleTaskManager() {
        if (root.taskManagerRequested) {
            closeWindowByType("taskManager")
        } else {
            openTaskManager()
        }
    }

    function openNotes() {
        root.isNotesClosing = false
        root.notesRequested = true
    }

    function toggleNotes() {
        if (root.notesRequested) {
            closeWindowByType("notes")
        } else {
            openNotes()
        }
    }

    function openWallpaper() {
        root.isWallpaperClosing = false
        root.wallpaperRequested = true
    }

    function toggleWallpaper() {
        if (root.wallpaperRequested) {
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
        } else if (windowType === "taskManager") {
            root.isTaskManagerClosing = true
            taskManagerCloseTimer.restart()
        } else if (windowType === "notes") {
            root.isNotesClosing = true
            notesCloseTimer.restart()
        }
    }

    Timer { 
        id: settingsCloseTimer
        interval: 350
        onTriggered: { 
            root.settingsRequested = false
            root.isSettingsClosing = false 
        } 
    }

    Timer { 
        id: controlPanelCloseTimer
        interval: 350
        onTriggered: { 
            root.controlPanelRequested = false
            root.isControlPanelClosing = false 
        } 
    }

    Timer { 
        id: wallpaperCloseTimer
        interval: 350
        onTriggered: { 
            root.wallpaperRequested = false
            root.isWallpaperClosing = false 
        } 
    }

    Timer { 
        id: taskManagerCloseTimer
        interval: 350
        onTriggered: { 
            root.taskManagerRequested = false
            root.isTaskManagerClosing = false 
        } 
    }

    Timer { 
        id: notesCloseTimer
        interval: 350
        onTriggered: { 
            root.notesRequested = false
            root.isNotesClosing = false 
        } 
    }
}
