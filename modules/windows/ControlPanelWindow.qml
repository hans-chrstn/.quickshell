import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.config
import qs.components
import qs.services

PanelWindow {
    id: root
    
    visible: false
    color: "transparent"
    
    anchors { left: true; right: true; top: true; bottom: true }
    exclusionMode: visible ? ExclusionMode.Normal : ExclusionMode.Ignore
    focusable: visible

    property string activePage: "wifi"

    Rectangle {
        anchors.fill: parent; color: "black"
        opacity: root.visible ? 0.6 : 0
        Behavior on opacity { NumberAnimation { duration: 400 } }
        MouseArea { anchors.fill: parent; onClicked: root.visible = false }
    }

    ClippingRectangle {
        id: windowFrame
        width: 600; height: 500
        anchors.centerIn: parent; radius: 32
        color: "#080809"; border.color: Qt.rgba(1, 1, 1, 0.1); border.width: 1
        
        opacity: root.visible ? 1.0 : 0
        scale: root.visible ? 1.0 : 0.95
        Behavior on opacity { NumberAnimation { duration: 300 } }
        Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }

        Rectangle {
            anchors.fill: parent; radius: 32; color: "transparent"
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.02) }
                GradientStop { position: 0.5; color: "transparent" }
            }
        }

        ColumnLayout {
            anchors.fill: parent; anchors.margins: 32; spacing: 24

            RowLayout {
                Layout.fillWidth: true
                Text { 
                    text: root.activePage === "wifi" ? "󰖩" : "󰂯"
                    color: FrameConfig.accentColor; font.pixelSize: 32 
                }
                ColumnLayout {
                    spacing: 0
                    Text { text: root.activePage.toUpperCase(); color: "white"; font.pixelSize: 14; font.weight: Font.Black; font.letterSpacing: 2 }
                    Text { text: "MANAGEMENT PANEL"; color: "white"; font.pixelSize: 10; opacity: 0.4; font.weight: Font.Bold }
                }
                Item { Layout.fillWidth: true }
                
                Rectangle {
                    width: 36; height: 36; radius: 18; color: "white"; opacity: hClose.hovered ? 0.2 : 0.1
                    Text { anchors.centerIn: parent; text: "󰅖"; color: "white"; font.pixelSize: 18 }
                    TapHandler { onTapped: root.visible = false }
                    HoverHandler { id: hClose; cursorShape: Qt.PointingHandCursor }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: "white"; opacity: 0.05 }

            ListView {
                id: listView
                Layout.fillWidth: true; Layout.fillHeight: true
                clip: true; spacing: 10
                model: root.activePage === "wifi" ? WifiService.model : BluetoothService.model
                
                delegate: ControlPanelDelegate {
                    width: listView.width
                    pageType: root.activePage
                }
            }

            ControlPanelFooter {
                pageType: root.activePage
            }
        }
    }
}