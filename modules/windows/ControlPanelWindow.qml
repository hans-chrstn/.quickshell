import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
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
                model: root.activePage === "wifi" ? SystemControl.wifiModel : SystemControl.bluetoothModel
                
                delegate: Rectangle {
                    width: listView.width; height: 60; radius: 16
                    color: "white"; opacity: hItem.hovered ? 0.08 : 0.04
                    
                    RowLayout {
                        anchors.fill: parent; anchors.margins: 16; spacing: 16
                        Text { 
                            text: root.activePage === "wifi" ? "󰖩" : "󰂯"
                            color: model.active ? FrameConfig.accentColor : "white"
                            opacity: 0.5; font.pixelSize: 20 
                        }
                        ColumnLayout {
                            spacing: 0
                            Text { text: model.name || "Unknown"; color: "white"; font.weight: Font.Medium; font.pixelSize: 13 }
                            Text { 
                                text: root.activePage === "wifi" ? (model.active ? "Connected" : "Signal: " + model.signal + "%") : (model.address || "Available")
                                color: model.active ? FrameConfig.accentColor : "white"; font.pixelSize: 10; opacity: 0.6 
                            }
                        }
                        Item { Layout.fillWidth: true }
                        Text { text: model.active ? "󰄬" : ""; color: FrameConfig.accentColor; font.pixelSize: 18 }
                    }
                    
                    TapHandler { 
                        onTapped: {
                            if (root.activePage === "wifi") {
                                Quickshell.execDetached(["nmcli", "device", "wifi", "connect", model.name])
                            } else {
                                Quickshell.execDetached(["bluetoothctl", "connect", model.address])
                            }
                        } 
                    }
                    HoverHandler { id: hItem; cursorShape: Qt.PointingHandCursor }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Text { 
                    text: root.activePage.toUpperCase() + " POWER"
                    color: "white"; font.pixelSize: 11; font.weight: Font.Black; opacity: 0.6 
                }
                Item { Layout.fillWidth: true }
                
                Rectangle {
                    width: 120; height: 40; radius: 20
                    color: (root.activePage === "wifi" ? SystemControl.wifiEnabled : SystemControl.bluetoothEnabled) ? FrameConfig.accentColor : "#FFFFFF"
                    opacity: (root.activePage === "wifi" ? SystemControl.wifiEnabled : SystemControl.bluetoothEnabled) ? 1.0 : 0.1
                    
                    Text {
                        anchors.centerIn: parent
                        text: (root.activePage === "wifi" ? SystemControl.wifiEnabled : SystemControl.bluetoothEnabled) ? "ENABLED" : "DISABLED"
                        color: (root.activePage === "wifi" ? SystemControl.wifiEnabled : SystemControl.bluetoothEnabled) ? "black" : "white"
                        font.pixelSize: 10; font.weight: Font.Black
                    }
                    
                    TapHandler {
                        onTapped: {
                            if (root.activePage === "wifi") SystemControl.toggleWifi()
                            else SystemControl.toggleBluetooth()
                        }
                    }
                    HoverHandler { id: hToggle; cursorShape: Qt.PointingHandCursor }
                }
            }
        }
    }
}
