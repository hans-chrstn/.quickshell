import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.core
import qs.ui.shared

Item {
    id: root
    
    width: (parent ? parent.width : 0) - 24
    height: 60
    anchors.horizontalCenter: (parent ? parent.horizontalCenter : undefined)
    
    property string panelType: "wifi"
    readonly property bool isNMDevice: model.type !== undefined
    readonly property bool isConnected: {
        if (root.panelType === "bluetooth") {
            return model.isActive
        }
        if (root.isNMDevice) {
            return model.state === "connected"
        }
        return model.isActive
    }

    readonly property bool isHovered: interactionHandler.hovered

    function mainAction() {
        if (root.panelType === "bluetooth") {
            if (root.isConnected) {
                Quickshell.execDetached(["bluetoothctl", "disconnect", model.address])
            } else {
                Quickshell.execDetached(["bluetoothctl", "connect", model.address])
            }
            return
        }
        
        if (root.panelType === "wifi") {
            if (root.isNMDevice) {
                if (root.isConnected) {
                    Quickshell.execDetached(["nmcli", "device", "disconnect", model.name])
                } else {
                    Quickshell.execDetached(["nmcli", "device", "connect", model.name])
                }
            } else {
                Quickshell.execDetached(["sh", "-c", "nmcli device wifi connect \"" + model.name + "\" --ask"])
            }
        }
    }

    Rectangle {
        id: backgroundVisual
        anchors.fill: parent
        radius: 16
        color: ThemeManager.contentOnBackgroundColor
        opacity: root.isHovered ? 0.08 : 0.04
        
        Behavior on opacity {
            NumberAnimation {
                duration: 200
            }
        }

        TapHandler {
            onTapped: {
                root.mainAction()
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16
        
        StyledLabel { 
            text: {
                if (root.panelType === "bluetooth") {
                    return "󰂯"
                }
                if (!root.isNMDevice) {
                    return "󰖩"
                }
                let type = model.type.toLowerCase()
                if (type.includes("wifi")) {
                    return "󰖩"
                }
                if (type.includes("ethernet")) {
                    return "󰈀"
                }
                return "󰖩"
            }
            type: "icon"
            customColor: root.isConnected ? ThemeManager.accentColor : ThemeManager.surfaceContentColor
            opacity: 0.8
        }
        
        ColumnLayout {
            spacing: 0
            
            StyledLabel { 
                text: model.name || "Unknown Device"
                type: "networkLabel"
                customColor: ThemeManager.surfaceContentColor
            }
            
            StyledLabel { 
                text: {
                    if (root.panelType === "bluetooth") {
                        return model.address || "Available"
                    }
                    if (!root.isNMDevice) {
                        return model.isActive ? "Connected" : "Signal: " + model.signal + "%"
                    }
                    return model.state.toUpperCase() + (model.connection ? " (" + model.connection + ")" : "")
                }
                type: "caption"
                customColor: root.isConnected ? ThemeManager.accentColor : ThemeManager.surfaceContentColor
                opacity: 0.6 
            }
        }
        
        Item {
            Layout.fillWidth: true 
        }

        RowLayout {
            spacing: 12
            visible: root.isHovered
            z: 10
            
            BaseButton {
                id: forgetBtn
                width: 32
                height: 32
                visible: {
                    if (root.panelType === "bluetooth") {
                        return !!model.isPaired
                    }
                    if (root.isNMDevice) {
                        return model.connection !== ""
                    }
                    return model.isActive
                }
                
                onClicked: {
                    if (root.panelType === "bluetooth") {
                        Quickshell.execDetached(["bluetoothctl", "remove", model.address])
                    } else if (root.isNMDevice) {
                        Quickshell.execDetached(["nmcli", "connection", "delete", model.connection])
                    } else {
                        Quickshell.execDetached(["nmcli", "connection", "delete", model.name])
                    }
                }
                
                Rectangle {
                    anchors.fill: parent
                    radius: 16
                    color: ThemeManager.dangerSurfaceColor
                    opacity: forgetBtn.isHovered ? 0.4 : 0.2
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 200
                        }
                    }
                }
                
                StyledLabel {
                    anchors.centerIn: parent
                    text: "󰆴"
                    type: "icon"
                    font.pixelSize: 14
                    customColor: ThemeManager.dangerColor
                }
            }

            BaseButton {
                id: toggleBtn
                width: 32
                height: 32
                onClicked: {
                    root.mainAction()
                }
                
                Rectangle {
                    anchors.fill: parent
                    radius: 16
                    color: root.isConnected ? ThemeManager.dangerSurfaceColor : ThemeManager.accentColor
                    opacity: root.isConnected ? (toggleBtn.isHovered ? 0.4 : 0.2) : (toggleBtn.isHovered ? 0.3 : 0.15)
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 200
                        }
                    }
                }
                
                StyledLabel {
                    anchors.centerIn: parent
                    text: root.isConnected ? "󰅖" : "󰄬"
                    type: "icon"
                    font.pixelSize: 14
                    customColor: root.isConnected ? ThemeManager.dangerColor : ThemeManager.accentColor
                }
            }
        }
        
        StyledLabel { 
            visible: !root.isHovered && root.isConnected
            text: "󰄬"
            type: "icon"
            customColor: ThemeManager.accentColor
        }
    }

    HoverHandler { 
        id: interactionHandler
        cursorShape: Qt.PointingHandCursor 
    }
    
    scale: interactionHandler.hovered ? 1.01 : 1.0
    Behavior on scale {
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutCubic
        }
    }
}
