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

    property bool isSettingsClosing: false
    property bool isControlPanelClosing: false
    property bool isWallpaperClosing: false
    property bool isTaskManagerClosing: false
    property bool isNotesClosing: false

    signal windowOpening(string windowType)
    signal windowClosing(string windowType)

    LazyLoader { 
        id: settingsLdr
        activeAsync: true 
        SettingsWindow { 
            visible: root.settingsRequested
            closing: root.isSettingsClosing
            screen: root.primaryScreen 
        } 
    }
    
    LazyLoader { 
        id: wallpaperLdr
        activeAsync: true 
        WallpaperWindow { 
            visible: root.wallpaperRequested
            closing: root.isWallpaperClosing
            screen: root.primaryScreen 
        } 
    }
    
    LazyLoader { 
        id: controlPanelLdr
        activeAsync: true 
        ControlPanelWindow { 
            visible: root.controlPanelRequested
            closing: root.isControlPanelClosing
            screen: root.primaryScreen 
        } 
    }
    
    LazyLoader { 
        id: taskManagerLdr
        activeAsync: true 
        TaskManagerWindow { 
            visible: root.taskManagerRequested
            closing: root.isTaskManagerClosing
            screen: root.primaryScreen 
        } 
    }

    LazyLoader { 
        id: notesLdr
        activeAsync: true 
        NotesWindow { 
            visible: root.notesRequested
            closing: root.isNotesClosing
            screen: root.primaryScreen 
        } 
    }

    function openSettings() {
        root.isSettingsClosing = false
        root.settingsRequested = true
        root.windowOpening("settings")
    }

    function toggleSettings() {
        if (root.settingsRequested && !root.isSettingsClosing) {
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
        root.windowOpening("controlPanel")
    }

    function toggleControlPanel(page = "wifi") {
        if (root.controlPanelRequested && !root.isControlPanelClosing && controlPanelLdr.item && controlPanelLdr.item.activePage === page) {
            closeWindowByType("controlPanel")
        } else {
            openControlPanel(page)
        }
    }

    function openTaskManager() {
        root.isTaskManagerClosing = false
        root.taskManagerRequested = true
        root.windowOpening("taskManager")
    }

    function toggleTaskManager() {
        if (root.taskManagerRequested && !root.isTaskManagerClosing) {
            closeWindowByType("taskManager")
        } else {
            openTaskManager()
        }
    }

    function openNotes() {
        root.isNotesClosing = false
        root.notesRequested = true
        root.windowOpening("notes")
    }

    function toggleNotes() {
        if (root.notesRequested && !root.isNotesClosing) {
            closeWindowByType("notes")
        } else {
            openNotes()
        }
    }

    function openWallpaper() {
        root.isWallpaperClosing = false
        root.wallpaperRequested = true
        root.windowOpening("wallpaper")
    }

    function toggleWallpaper() {
        if (root.wallpaperRequested && !root.isWallpaperClosing) {
            closeWindowByType("wallpaper")
        } else {
            openWallpaper()
        }
    }

    function closeWindowByType(windowType) {
        if (windowType === "settings") {
            root.isSettingsClosing = true
            root.windowClosing("settings")
            settingsCloseTimer.restart()
        } else if (windowType === "controlPanel") {
            root.isControlPanelClosing = true
            root.windowClosing("controlPanel")
            controlPanelCloseTimer.restart()
        } else if (windowType === "wallpaper") {
            root.isWallpaperClosing = true
            root.windowClosing("wallpaper")
            wallpaperCloseTimer.restart()
        } else if (windowType === "taskManager") {
            root.isTaskManagerClosing = true
            root.windowClosing("taskManager")
            taskManagerCloseTimer.restart()
        } else if (windowType === "notes") {
            root.isNotesClosing = true
            root.windowClosing("notes")
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
