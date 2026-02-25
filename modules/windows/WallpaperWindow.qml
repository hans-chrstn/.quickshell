import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.services
import qs.components
import qs.modules.windows

PanelWindow {
    id: root
    
    visible: false
    color: "transparent"
    
    anchors { 
        left: true; right: true; top: true; bottom: true 
    }
    
    exclusionMode: visible ? ExclusionMode.Normal : ExclusionMode.Ignore
    focusable: visible
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    Shortcut {
        sequence: "Escape"
        enabled: root.visible
        onActivated: ViewManager.closeWindowByType("wallpaper")
    }

    onVisibleChanged: {
        if (visible) {
            Qt.callLater(() => {
                explorer.forceActiveFocus()
            })
        }
    }

    Rectangle {
        anchors.fill: parent; color: ThemeManager.shadowPrimaryColor
        opacity: (root.visible && !ViewManager.isWallpaperClosing) ? 0.6 : 0
        Behavior on opacity { NumberAnimation { duration: 300 } }
        MouseArea { anchors.fill: parent; onClicked: ViewManager.closeWindowByType("wallpaper") }
    }

    ClippingRectangle {
        id: windowFrame
        width: 1120; height: 700
        anchors.centerIn: parent; radius: 36
        color: ThemeManager.backgroundPrimaryColor; border.color: ThemeManager.outlinePrimaryColor; border.width: 1
        
        opacity: (root.visible && !ViewManager.isWallpaperClosing) ? 1.0 : 0
        scale: (root.visible && !ViewManager.isWallpaperClosing) ? 1.0 : 0.95
        
        Behavior on opacity { NumberAnimation { duration: 300 } }
        Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }

        MouseArea { anchors.fill: parent; onPressed: (mouse) => mouse.accepted = true }

        Rectangle {
            anchors.fill: parent; radius: 36; color: "transparent"
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(ThemeManager.contentOnBackgroundColor.r, ThemeManager.contentOnBackgroundColor.g, ThemeManager.contentOnBackgroundColor.b, 0.02) }
                GradientStop { position: 0.5; color: "transparent" }
            }
        }

        RowLayout {
            anchors.fill: parent
            spacing: 0

            Item {
                Layout.fillWidth: true; Layout.fillHeight: true
                
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 40 
                    width: 600
                    
                    ColumnLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 24 
                        
                        WallpaperPreview { }

                        WallpaperControls {
                            id: wallpaperControls
                            rootWindow: root
                            activeFocusOnTab: true
                        }
                    }
                }
            }

            Rectangle { 
                width: 1; Layout.fillHeight: true; color: ThemeManager.contentOnBackgroundColor; opacity: 0.05 
            }

            Rectangle {
                Layout.preferredWidth: 420; Layout.fillHeight: true; color: ThemeManager.surfaceSubtleColor
                
                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 24; spacing: 20
                    
                    WallpaperExplorer {
                        id: explorer
                        Layout.fillWidth: true; Layout.fillHeight: true
                        activeFocusOnTab: true

                        Item {
                            Layout.fillWidth: true; Layout.fillHeight: true
                            visible: explorer.showSettings
                            
                            WallpaperSettings {
                                anchors.fill: parent
                            }
                        }
                    }
                }
            }
        }
    }
}
