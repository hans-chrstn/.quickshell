import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.core
import qs.ui.panels
import qs.ui.features.island
import qs.ui.features.island.corners
import qs.ui.screens
import qs.ui.features.notifications
    import qs.ui.features.gestures

Item {
    id: root

    readonly property var _viewManager: ViewManager
    readonly property var _launcherManager: LauncherManager
    readonly property var _clipboardManager: ClipboardManager

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
            active: AreaPickerManager.active
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
            active: LauncherManager.active || ViewManager.isRequested("commandPalette")
            component: CommandPaletteWindow {
                screen: launcherDelegate.modelData
            }
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: LazyContainer {
            id: settingsLdr
            required property var modelData
            active: ViewManager.isRequested("settings") && (ViewManager.lastActiveScreenName === modelData.name)
            component: SettingsWindow {
                screen: settingsLdr.modelData
                closing: ViewManager.isClosing("settings")
            }
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: LazyContainer {
            id: wallpaperLdr
            required property var modelData
            active: ViewManager.isRequested("wallpaper") && (ViewManager.lastActiveScreenName === modelData.name)
            component: WallpaperWindow {
                screen: wallpaperLdr.modelData
                closing: ViewManager.isClosing("wallpaper")
            }
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: LazyContainer {
            id: networkLdr
            required property var modelData
            active: ViewManager.isRequested("network") && (ViewManager.lastActiveScreenName === modelData.name)
            component: NetworkWindow {
                screen: networkLdr.modelData
                closing: ViewManager.isClosing("network")
            }
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: LazyContainer {
            id: bluetoothLdr
            required property var modelData
            active: ViewManager.isRequested("bluetooth") && (ViewManager.lastActiveScreenName === modelData.name)
            component: BluetoothWindow {
                screen: bluetoothLdr.modelData
                closing: ViewManager.isClosing("bluetooth")
            }
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: LazyContainer {
            id: taskManagerLdr
            required property var modelData
            active: ViewManager.isRequested("taskManager") && (ViewManager.lastActiveScreenName === modelData.name)
            component: TaskManagerWindow {
                screen: taskManagerLdr.modelData
                closing: ViewManager.isClosing("taskManager")
            }
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: LazyContainer {
            id: notesLdr
            required property var modelData
            active: ViewManager.isRequested("notes") && (ViewManager.lastActiveScreenName === modelData.name)
            component: NotesWindow {
                screen: notesLdr.modelData
                closing: ViewManager.isClosing("notes")
            }
        }
    }


    Variants {
        model: Quickshell.screens
        delegate: PanelWindow {
            id: dragOverlay
            required property var modelData
            screen: modelData
            
            anchors { left: true; right: true; top: true; bottom: true }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            color: "transparent"
            
            visible: ViewManager.isDragging && (ViewManager.lastActiveScreenName === modelData.name)
            
            mask: Region {
                Region { item: ghost }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                
                onPositionChanged: (mouse) => {
                    ViewManager.dragX = dragOverlay.screen.x + mouse.x
                    ViewManager.dragY = dragOverlay.screen.y + mouse.y
                    ViewManager.checkDropTarget(ViewManager.dragX, ViewManager.dragY)
                }
                
                onReleased: {
                    if (ViewManager.hoveredTargetWorkspaceRef !== null) {
                        WindowManager.moveWindowToWorkspace(
                            ViewManager.activeDragWindowId, 
                            ViewManager.hoveredTargetWorkspaceRef
                        )
                    }
                    
                    ViewManager.activeDragWindowId = null
                    ViewManager.activeDragIcon = ""
                    ViewManager.hoveredTargetWorkspaceId = -1
                    ViewManager.hoveredTargetWorkspaceRef = null
                    ViewManager.setHoveredWorkspace(-1)
                }
            }

            Rectangle {
                id: ghost
                width: 80
                height: 80
                radius: 16
                color: Qt.rgba(ThemeManager.accentColor.r, ThemeManager.accentColor.g, ThemeManager.accentColor.b, 0.6)
                border.color: "white"
                border.width: 2
                
                x: (ViewManager.dragX - dragOverlay.screen.x) - (width / 2)
                y: (ViewManager.dragY - dragOverlay.screen.y) - (height / 2)
                
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: "black"
                    shadowOpacity: 0.8
                    shadowBlur: 0.5
                }

                Image {
                    anchors.fill: parent
                    anchors.margins: 16
                    source: ViewManager.activeDragIcon ? "file://" + ViewManager.activeDragIcon : ""
                    smooth: true
                }
            }
        }
    }

    Tooltip { }

    GestureHUD {
      id: gestureHUD
    }
}
