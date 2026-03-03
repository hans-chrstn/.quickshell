import QtQuick
import Quickshell
import qs.core
import qs.ui.panels
import qs.ui.features.island
import qs.ui.features.island.corners
import qs.ui.screens
import qs.ui.features.notifications

Item {
    id: root

    Variants {
        model: Quickshell.screens
        delegate: LazyContainer {
            id: topBarDelegate
            required property var modelData
            
            component: TopBar { 
                aboveWindows: true 
                screen: topBarDelegate.modelData
            }
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: LazyContainer {
            id: leftBarDelegate
            required property var modelData
            
            component: LeftBar { 
                aboveWindows: true 
                screen: leftBarDelegate.modelData
            }
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: LazyContainer {
            id: rightBarDelegate
            required property var modelData
            
            component: RightBar { 
                aboveWindows: true 
                screen: rightBarDelegate.modelData
            }
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: LazyContainer {
            id: bottomBarDelegate
            required property var modelData
            
            component: BottomBar { 
                aboveWindows: true 
                screen: bottomBarDelegate.modelData
            }
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: LazyContainer {
            id: topLeftDelegate
            required property var modelData
            
            component: CornerTopLeft {
                screen: topLeftDelegate.modelData
            }
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: LazyContainer {
            id: topRightDelegate
            required property var modelData
            
            component: CornerTopRight {
                screen: topRightDelegate.modelData
            }
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: LazyContainer {
            id: bottomLeftDelegate
            required property var modelData
            
            component: CornerBottomLeft {
                screen: bottomLeftDelegate.modelData
            }
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: LazyContainer {
            id: bottomRightDelegate
            required property var modelData
            
            component: CornerBottomRight {
                screen: bottomRightDelegate.modelData
            }
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: LazyContainer {
            id: notificationDelegate
            required property var modelData
            
            component: NotificationPopup { 
                modelData: notificationDelegate.modelData
            }
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: LazyContainer {
            id: areaPickerDelegate
            required property var modelData
            
            component: AreaPickerWindow { 
                screen: areaPickerDelegate.modelData
            }
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: LazyContainer {
            id: launcherDelegate
            required property var modelData
            
            component: LauncherWindow { 
                screen: launcherDelegate.modelData
            }
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: LazyContainer {
            id: settingsLdr
            required property var modelData
            active: ViewManager.settingsRequested && (ViewManager.lastActiveScreenName === modelData.name)
            component: SettingsWindow {
                screen: settingsLdr.modelData
                closing: ViewManager.isSettingsClosing
            }
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: LazyContainer {
            id: wallpaperLdr
            required property var modelData
            active: ViewManager.wallpaperRequested && (ViewManager.lastActiveScreenName === modelData.name)
            component: WallpaperWindow {
                screen: wallpaperLdr.modelData
                closing: ViewManager.isWallpaperClosing
            }
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: LazyContainer {
            id: networkLdr
            required property var modelData
            active: ViewManager.networkRequested && (ViewManager.lastActiveScreenName === modelData.name)
            component: NetworkWindow {
                screen: networkLdr.modelData
                closing: ViewManager.isNetworkClosing
            }
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: LazyContainer {
            id: bluetoothLdr
            required property var modelData
            active: ViewManager.bluetoothRequested && (ViewManager.lastActiveScreenName === modelData.name)
            component: BluetoothWindow {
                screen: bluetoothLdr.modelData
                closing: ViewManager.isBluetoothClosing
            }
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: LazyContainer {
            id: taskManagerLdr
            required property var modelData
            active: ViewManager.taskManagerRequested && (ViewManager.lastActiveScreenName === modelData.name)
            component: TaskManagerWindow {
                screen: taskManagerLdr.modelData
                closing: ViewManager.isTaskManagerClosing
            }
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: LazyContainer {
            id: notesLdr
            required property var modelData
            active: ViewManager.notesRequested && (ViewManager.lastActiveScreenName === modelData.name)
            component: NotesWindow {
                screen: notesLdr.modelData
                closing: ViewManager.isNotesClosing
            }
        }
    }
}
