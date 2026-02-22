import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.services

Rectangle {
    id: root
    width: parent ? parent.width : 0
    height: 60
    radius: 16
    color: "white"
    opacity: hItem.hovered ? 0.08 : 0.04
    
    property string pageType: "wifi"

    RowLayout {
        anchors.fill: parent; anchors.margins: 16; spacing: 16
        Text { 
            text: root.pageType === "wifi" ? "󰖩" : "󰂯"
            color: model.active ? FrameConfig.accentColor : "white"
            opacity: 0.5; font.pixelSize: 20 
        }
        ColumnLayout {
            spacing: 0
            Text { text: model.name || "Unknown"; color: "white"; font.weight: Font.Medium; font.pixelSize: 13 }
            Text { 
                text: root.pageType === "wifi" ? (model.active ? "Connected" : "Signal: " + model.signal + "%") : (model.address || "Available")
                color: model.active ? FrameConfig.accentColor : "white"; font.pixelSize: 10; opacity: 0.6 
            }
        }
        Item { Layout.fillWidth: true }
        Text { text: model.active ? "󰄬" : ""; color: FrameConfig.accentColor; font.pixelSize: 18 }
    }
    
    TapHandler { 
        onTapped: {
            if (root.pageType === "wifi") {
                Quickshell.execDetached(["nmcli", "device", "wifi", "connect", model.name])
            } else {
                Quickshell.execDetached(["bluetoothctl", "connect", model.address])
            }
        } 
    }
    HoverHandler { id: hItem; cursorShape: Qt.PointingHandCursor }
}
