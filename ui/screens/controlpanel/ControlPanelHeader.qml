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
        Layout.fillWidth: true
    }

    Rectangle {
        width: 36
        height: 36
        radius: 18
        color: ThemeManager.contentOnBackgroundColor
        opacity: hSet.hovered ? 0.2 : 0.1
        scale: hSet.hovered ? 1.1 : 1.0
        
        Behavior on opacity {
            NumberAnimation {
                duration: 200
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutQuart
            }
        }

        StyledLabel {
            anchors.centerIn: parent
            text: "󰒓"
            type: "body"
            font.pixelSize: 18
        }

        TapHandler {
            onTapped: {
                ViewManager.openSettings()
                SoundManager.playClick()
            }
        }

        HoverHandler {
            id: hSet
            cursorShape: Qt.PointingHandCursor
        }
    }

    Rectangle {
        width: 36
        height: 36
        radius: 18
        color: ThemeManager.contentOnBackgroundColor
        opacity: hClose.hovered ? 0.2 : 0.1
        scale: hClose.hovered ? 1.1 : 1.0
        
        Behavior on opacity {
            NumberAnimation {
                duration: 200
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutQuart
            }
        }

        StyledLabel {
            anchors.centerIn: parent
            text: "󰅖"
            type: "body"
            font.pixelSize: 18
        }

        TapHandler {
            onTapped: {
                ViewManager.closeWindowByType("controlPanel")
            }
        }

        HoverHandler {
            id: hClose
            cursorShape: Qt.PointingHandCursor
        }
    }
}
