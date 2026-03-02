pragma Singleton
import QtQuick
import Quickshell
import qs.ui.screens
import qs.ui.shared

Singleton {
    id: root

    readonly property var primaryScreen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null

    property bool settingsRequested: false
    property bool wallpaperRequested: false
    property bool networkRequested: false
    property bool bluetoothRequested: false
    property bool taskManagerRequested: false
    property bool notesRequested: false

    property bool isSettingsClosing: false
    property bool isNetworkClosing: false
    property bool isBluetoothClosing: false
    property bool isWallpaperClosing: false
    property bool isTaskManagerClosing: false
    property bool isNotesClosing: false

    signal windowOpening(string windowType)
    signal windowClosing(string windowType)

    LazyContainer { 
        id: settingsLdr
        active: root.settingsRequested
        component: SettingsWindow { 
            visible: root.settingsRequested
            closing: root.isSettingsClosing
            screen: root.primaryScreen 
        } 
    }
    
    LazyContainer { 
        id: wallpaperLdr
        active: root.wallpaperRequested
        component: WallpaperWindow { 
            visible: root.wallpaperRequested
            closing: root.isWallpaperClosing
            screen: root.primaryScreen 
        } 
    }
    
    LazyContainer { 
        id: networkLdr
        active: root.networkRequested
        component: NetworkWindow { 
            visible: root.networkRequested
            closing: root.isNetworkClosing
            screen: root.primaryScreen 
        } 
    }

    LazyContainer { 
        id: bluetoothLdr
        active: root.bluetoothRequested
        component: BluetoothWindow { 
            visible: root.bluetoothRequested
            closing: root.isBluetoothClosing
            screen: root.primaryScreen 
        } 
    }
    
    LazyContainer { 
        id: taskManagerLdr
        active: root.taskManagerRequested
        component: TaskManagerWindow { 
            visible: root.taskManagerRequested
            closing: root.isTaskManagerClosing
            screen: root.primaryScreen 
        } 
    }

    LazyContainer { 
        id: notesLdr
        active: root.notesRequested
        component: NotesWindow { 
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

    function openNetwork() {
        root.isNetworkClosing = false
        root.networkRequested = true
        root.windowOpening("network")
    }

    function toggleNetwork() {
        if (root.networkRequested && !root.isNetworkClosing) {
            closeWindowByType("network")
        } else {
            openNetwork()
        }
    }

    function openBluetooth() {
        root.isBluetoothClosing = false
        root.bluetoothRequested = true
        root.windowOpening("bluetooth")
    }

    function toggleBluetooth() {
        if (root.bluetoothRequested && !root.isBluetoothClosing) {
            closeWindowByType("bluetooth")
        } else {
            openBluetooth()
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
        } else if (windowType === "network") {
            root.isNetworkClosing = true
            root.windowClosing("network")
            networkCloseTimer.restart()
        } else if (windowType === "bluetooth") {
            root.isBluetoothClosing = true
            root.windowClosing("bluetooth")
            bluetoothCloseTimer.restart()
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
        id: networkCloseTimer
        interval: 350
        onTriggered: { 
            root.networkRequested = false
            root.isNetworkClosing = false 
        } 
    }

    Timer { 
        id: bluetoothCloseTimer
        interval: 350
        onTriggered: { 
            root.bluetoothRequested = false
            root.isBluetoothClosing = false 
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
