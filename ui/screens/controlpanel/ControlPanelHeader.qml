import QtQuick
import QtQuick.Layouts
import qs.core
import qs.ui.shared

RowLayout {
    id: root
    
    property string activePage: "wifi"
    
    Layout.fillWidth: true
    spacing: 16

    StyledLabel {
        text: root.activePage === "wifi" ? "󰖩" : "󰂯"
        type: "heading"
        customColor: ThemeManager.accentColor
        font.pixelSize: 32
    }

    ColumnLayout {
        spacing: 0
        
        StyledLabel {
            text: (root.activePage === "wifi" ? "NETWORK" : root.activePage.toUpperCase())
            type: "controlPanelHeader"
        }
        
        StyledLabel {
            text: "MANAGEMENT PANEL"
            type: "caption"
            opacity: 0.4
            font.weight: Font.Bold
        }
    }

    Item {
        Layout.preferredWidth: 20
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 36
        Layout.maximumWidth: 300
        radius: 18
        color: ThemeManager.surfaceStrongColor
        border.color: ThemeManager.outlinePrimaryColor
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 8

            StyledLabel {
                text: ThemeManager.iconSearch
                type: "caption"
                font.pixelSize: 14
                opacity: controlSearchInput.activeFocus ? 1.0 : 0.3
                customColor: ThemeManager.accentColor
            }

            TextInput {
                id: controlSearchInput
                Layout.fillWidth: true
                color: ThemeManager.contentOnBackgroundColor
                font.family: ThemeManager.fontFamily
                font.pixelSize: 12
                selectionColor: ThemeManager.accentColor
                text: root.activePage === "wifi" ? NetworkManager.searchText : BluetoothManager.searchText
                
                onTextChanged: {
                    if (root.activePage === "wifi") {
                        NetworkManager.searchText = text
                    } else {
                        BluetoothManager.searchText = text
                    }
                }

                StyledLabel {
                    text: root.activePage === "wifi" ? "Search Wi-Fi..." : "Filter devices..."
                    type: "caption"
                    font.pixelSize: 12
                    opacity: 0.2
                    visible: !controlSearchInput.text && !controlSearchInput.activeFocus
                }
            }
        }
    }

    Item {
        Layout.fillWidth: true
    }
}
