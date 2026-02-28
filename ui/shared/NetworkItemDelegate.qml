import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.core
import qs.ui.shared

Rectangle {
    id: root
    
    width: parent ? parent.width : 0
    height: 60
    radius: 16
    color: ThemeManager.contentOnBackgroundColor
    opacity: interactionHandler.hovered ? 0.08 : 0.04
    scale: interactionHandler.hovered ? 1.01 : 1.0
    
    Behavior on opacity { NumberAnimation { duration: 200 } }
    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }
    
    property string panelType: "wifi"

    RowLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16
        
        StyledLabel { 
            text: root.panelType === "wifi" ? "󰖩" : "󰂯"
            type: "icon"
            customColor: model.isActive ? ThemeManager.accentColor : ThemeManager.contentOnBackgroundColor
            opacity: 0.5
        }
        
        ColumnLayout {
            spacing: 0
            StyledLabel { 
                text: model.name || "Unknown Device"
                type: "networkLabel"
            }
            StyledLabel { 
                text: root.panelType === "wifi" 
                    ? (model.isActive ? "Connected" : "Signal: " + model.signal + "%") 
                    : (model.address || "Available")
                type: "caption"
                customColor: model.isActive ? ThemeManager.accentColor : ThemeManager.contentOnBackgroundColor
                opacity: 0.6 
            }
        }
        
        Item { Layout.fillWidth: true }
        
        StyledLabel { 
            text: model.isActive ? "󰄬" : ""
            type: "icon"
            customColor: ThemeManager.accentColor
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
