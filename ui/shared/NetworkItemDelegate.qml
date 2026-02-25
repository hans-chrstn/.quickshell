import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.core

Rectangle {
    id: root
    
    width: parent ? parent.width : 0
    height: 60
    radius: 16
    color: ThemeManager.contentOnBackgroundColor
    opacity: interactionHandler.hovered ? 0.08 : 0.04
    
    property string panelType: "wifi"

    RowLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16
        
        Text { 
            text: root.panelType === "wifi" ? "󰖩" : "󰂯"
            color: model.isActive ? ThemeManager.accentColor : ThemeManager.contentOnBackgroundColor
            opacity: 0.5
            font.pixelSize: 20 
        }
        
        ColumnLayout {
            spacing: 0
            Text { 
                text: model.name || "Unknown Device"
                color: ThemeManager.contentOnBackgroundColor
                font.weight: Font.Medium
                font.pixelSize: 13 
            }
            Text { 
                text: root.panelType === "wifi" 
                    ? (model.isActive ? "Connected" : "Signal: " + model.signal + "%") 
                    : (model.address || "Available")
                color: model.isActive ? ThemeManager.accentColor : ThemeManager.contentOnBackgroundColor
                font.pixelSize: 10
                opacity: 0.6 
            }
        }
        
        Item { Layout.fillWidth: true }
        
        Text { 
            text: model.isActive ? "󰄬" : ""
            color: ThemeManager.accentColor
            font.pixelSize: 18 
        }
    }
    
    TapHandler { 
        onTapped: {
            if (root.panelType === "wifi") {
                Quickshell.execDetached(["nmcli", "device", "wifi", "connect", model.name])
            } else {
                Quickshell.execDetached(["bluetoothctl", "connect", model.address])
            }
        } 
    }
    
    HoverHandler { 
        id: interactionHandler
        cursorShape: Qt.PointingHandCursor 
    }
}
