import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import QtMultimedia
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.config
import qs.components
import qs.services
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

    Rectangle {
        anchors.fill: parent; color: "black"
        opacity: root.visible ? 0.6 : 0
        Behavior on opacity { NumberAnimation { duration: 400 } }
        MouseArea { anchors.fill: parent; onClicked: root.visible = false }
    }

    ClippingRectangle {
        id: windowFrame
        width: 1050; height: 680
        anchors.centerIn: parent; radius: 36
        color: "#080809"; border.color: Qt.rgba(1, 1, 1, 0.1); border.width: 1
        
        opacity: root.visible ? 1.0 : 0
        scale: root.visible ? 1.0 : 0.95
        Behavior on opacity { NumberAnimation { duration: 300 } }
        Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }

        MouseArea { anchors.fill: parent; onPressed: (mouse) => mouse.accepted = true }

        Rectangle {
            anchors.fill: parent; radius: 36; color: "transparent"
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.02) }
                GradientStop { position: 0.5; color: "transparent" }
            }
        }

        RowLayout {
            anchors.fill: parent
            spacing: 0

            Item {
                Layout.fillWidth: true; Layout.fillHeight: true
                
                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 32; spacing: 32
                    
                    WallpaperPreview { }

                    WallpaperControls {
                        rootWindow: root
                    }
                }
            }

            Rectangle { 
                width: 1; Layout.fillHeight: true; color: "white"; opacity: 0.05 
            }

            Rectangle {
                Layout.preferredWidth: 420; Layout.fillHeight: true; color: Qt.rgba(0, 0, 0, 0.15)
                
                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 24; spacing: 20
                    
                    WallpaperExplorer {
                        id: explorer
                        Layout.fillWidth: true; Layout.fillHeight: true
                        
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
