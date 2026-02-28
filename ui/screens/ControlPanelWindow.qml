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

    property bool entryStarted: false
    onVisibleChanged: {
        if (visible) {
            Qt.callLater(() => { entryStarted = true })
        } else {
            entryStarted = false
        }
    }

    Rectangle {
        anchors.fill: parent; color: ThemeManager.shadowPrimaryColor
        opacity: root.entryStarted ? 0.6 : 0
        Behavior on opacity { NumberAnimation { duration: 300 } }
        MouseArea { anchors.fill: parent; onClicked: ViewManager.closeWindowByType("controlPanel") }
    }

    ClippingRectangle {
        id: windowFrame
        width: 600; height: 500
        anchors.centerIn: parent; radius: 32
        color: ThemeManager.backgroundPrimaryColor; border.color: ThemeManager.outlinePrimaryColor; border.width: 1
        
        opacity: root.entryStarted ? 1.0 : 0
        scale: root.entryStarted ? 1.0 : 0.95
        
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
                StyledLabel { 
                    text: root.activePage === "wifi" ? "󰖩" : "󰂯"
                    type: "heading"
                    customColor: ThemeManager.accentColor
                    font.pixelSize: 32 
                }
                ColumnLayout {
                    spacing: 0
                    StyledLabel { text: root.activePage.toUpperCase(); type: "controlPanelHeader" }
                    StyledLabel { text: "MANAGEMENT PANEL"; type: "caption"; opacity: 0.4; font.weight: Font.Bold }
                }
                Item { Layout.fillWidth: true }
                
                Rectangle {
                    width: 36; height: 36; radius: 18; color: ThemeManager.contentOnBackgroundColor
                    opacity: hSet.hovered ? 0.2 : 0.1
                    scale: hSet.hovered ? 1.1 : 1.0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }
                    
                    StyledLabel { anchors.centerIn: parent; text: "󰒓"; type: "body"; font.pixelSize: 18 }
                    TapHandler { 
                        onTapped: {
                            ViewManager.openSettings()
                            SoundManager.playClick()
                        }
                    }
                    HoverHandler { id: hSet; cursorShape: Qt.PointingHandCursor }
                }

                Rectangle {
                    width: 36; height: 36; radius: 18; color: ThemeManager.contentOnBackgroundColor
                    opacity: hClose.hovered ? 0.2 : 0.1
                    scale: hClose.hovered ? 1.1 : 1.0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }
                    
                    StyledLabel { anchors.centerIn: parent; text: "󰅖"; type: "body"; font.pixelSize: 18 }
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
