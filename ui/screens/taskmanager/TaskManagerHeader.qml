import QtQuick
import QtQuick.Layouts
import qs.core
import qs.ui.shared

RowLayout {
    id: root
    
    property bool isSidebarExpanded: true
    signal toggleSidebar()

    Layout.fillWidth: true
    spacing: 16

    BaseButton {
        width: 36
        height: 36
        cornerRadius: 10
        onClicked: root.toggleSidebar()
        
        opacity: isHovered ? 1.0 : 0.6
        Behavior on opacity { NumberAnimation { duration: 200 } }

        StyledLabel {
            anchors.centerIn: parent
            text: root.isSidebarExpanded ? "󰍜" : "󰍝"
            type: "icon"
            font.pixelSize: 20
            customColor: root.isSidebarExpanded ? ThemeManager.accentColor : ThemeManager.surfaceContentColor
        }
    }

    StyledLabel {
        text: ThemeManager.iconTasks
        type: "heading"
        customColor: ThemeManager.accentColor
        font.pixelSize: 32
    }

    ColumnLayout {
        spacing: 0
        
        StyledLabel {
            text: "SYSTEM TASKS"
            type: "controlPanelHeader"
        }
        
        StyledLabel {
            text: "RESOURCE MONITOR"
            type: "caption"
            opacity: 0.4
            font.weight: Font.Bold
        }
    }

    Item {
        Layout.fillWidth: true
    }

    Rectangle {
        Layout.preferredWidth: 240
        Layout.preferredHeight: 36
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
                opacity: taskSearchInput.activeFocus ? 1.0 : 0.3
                customColor: ThemeManager.accentColor
            }

            TextInput {
                id: taskSearchInput
                Layout.fillWidth: true
                color: ThemeManager.contentOnBackgroundColor
                font.family: ThemeManager.fontFamily
                font.pixelSize: 12
                selectionColor: ThemeManager.accentColor
                text: ProcessManager.searchText
                
                onTextChanged: {
                    ProcessManager.searchText = text
                }

                StyledLabel {
                    text: "Filter tasks..."
                    type: "caption"
                    font.pixelSize: 12
                    opacity: 0.2
                    visible: !taskSearchInput.text && !taskSearchInput.activeFocus
                }
            }
        }
    }

    Row {
        spacing: 8
        
        Repeater {
            model: ["cpu", "mem", "pid", "name"]
            delegate: Rectangle {
                width: 60
                height: 28
                radius: 14
                color: ProcessManager.sortBy === modelData ? ThemeManager.accentColor : ThemeManager.surfacePrimaryColor
                opacity: ProcessManager.sortBy === modelData ? 1.0 : 0.5
                
                StyledLabel {
                    anchors.centerIn: parent
                    text: modelData.toUpperCase()
                    type: "caption"
                    font.weight: Font.Black
                    customColor: ProcessManager.sortBy === modelData ? ThemeManager.contentPrimaryColor : ThemeManager.contentOnBackgroundColor
                }
                
                TapHandler {
                    onTapped: {
                        ProcessManager.sortBy = modelData
                    }
                }
                
                HoverHandler {
                    cursorShape: Qt.PointingHandCursor
                }
            }
        }
    }
}
