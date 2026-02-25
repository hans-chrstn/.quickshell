import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.ui.shared
import qs.core

PanelWindow {
    id: root
    
    visible: false
    color: "transparent"
    
    anchors { left: true; right: true; top: true; bottom: true }
    exclusionMode: visible ? ExclusionMode.Normal : ExclusionMode.Ignore
    focusable: visible

    property string activePage: "wifi"

    Rectangle {
        anchors.fill: parent; color: ThemeManager.shadowPrimaryColor
        opacity: (root.visible && !ViewManager.isControlPanelClosing) ? 0.6 : 0
        Behavior on opacity { NumberAnimation { duration: 300 } }
        MouseArea { anchors.fill: parent; onClicked: ViewManager.closeWindowByType("controlPanel") }
    }

    ClippingRectangle {
        id: windowFrame
        width: 600; height: 500
        anchors.centerIn: parent; radius: 32
        color: ThemeManager.backgroundPrimaryColor; border.color: ThemeManager.outlinePrimaryColor; border.width: 1
        
        opacity: (root.visible && !ViewManager.isControlPanelClosing) ? 1.0 : 0
        scale: (root.visible && !ViewManager.isControlPanelClosing) ? 1.0 : 0.95
        
        Behavior on opacity { NumberAnimation { duration: 300 } }
        Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }

        Rectangle {
            anchors.fill: parent; radius: 32; color: "transparent"
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(ThemeManager.contentOnBackgroundColor.r, ThemeManager.contentOnBackgroundColor.g, ThemeManager.contentOnBackgroundColor.b, 0.02) }
                GradientStop { position: 0.5; color: "transparent" }
            }
        }

        ColumnLayout {
            anchors.fill: parent; anchors.margins: 32; spacing: 24

            RowLayout {
                Layout.fillWidth: true
                Text { 
                    text: root.activePage === "wifi" ? "󰖩" : "󰂯"
                    color: ThemeManager.accentColor; font.pixelSize: 32 
                }
                ColumnLayout {
                    spacing: 0
                    Text { text: root.activePage.toUpperCase(); color: ThemeManager.contentOnBackgroundColor; font.pixelSize: 14; font.weight: Font.Black; font.letterSpacing: 2 }
                    Text { text: "MANAGEMENT PANEL"; color: ThemeManager.contentOnBackgroundColor; font.pixelSize: 10; opacity: 0.4; font.weight: Font.Bold }
                }
                Item { Layout.fillWidth: true }
                
                Rectangle {
                    width: 36; height: 36; radius: 18; color: ThemeManager.contentOnBackgroundColor; opacity: hSet.hovered ? 0.2 : 0.1
                    Text { anchors.centerIn: parent; text: "󰒓"; color: ThemeManager.contentOnBackgroundColor; font.pixelSize: 18 }
                    TapHandler { 
                        onTapped: {
                            ViewManager.openSettings()
                            SoundManager.playClick()
                        }
                    }
                    HoverHandler { id: hSet; cursorShape: Qt.PointingHandCursor }
                }

                Rectangle {
                    width: 36; height: 36; radius: 18; color: ThemeManager.contentOnBackgroundColor; opacity: hClose.hovered ? 0.2 : 0.1
                    Text { anchors.centerIn: parent; text: "󰅖"; color: ThemeManager.contentOnBackgroundColor; font.pixelSize: 18 }
                    TapHandler { onTapped: ViewManager.closeWindowByType("controlPanel") }
                    HoverHandler { id: hClose; cursorShape: Qt.PointingHandCursor }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: ThemeManager.contentOnBackgroundColor; opacity: 0.05 }

            ListView {
                id: listView
                Layout.fillWidth: true; Layout.fillHeight: true
                clip: true; spacing: 10
                model: root.activePage === "wifi" ? WifiManager.networkModel : BluetoothManager.deviceModel
                
                delegate: NetworkItemDelegate {
                    width: listView.width
                    panelType: root.activePage
                }
            }

            NetworkPanelFooter {
                panelType: root.activePage
            }
        }
    }
}
