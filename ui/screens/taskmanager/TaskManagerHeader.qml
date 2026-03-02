import QtQuick
import QtQuick.Layouts
import qs.core
import qs.ui.shared

RowLayout {
    id: root
    
    Layout.fillWidth: true
    spacing: 16

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

    BaseButton {
        width: 36
        height: 36
        onClicked: {
            ViewManager.closeWindowByType("taskManager")
        }
        
        Rectangle {
            anchors.fill: parent
            radius: 18
            color: ThemeManager.surfacePrimaryColor
            
            StyledLabel {
                anchors.centerIn: parent
                text: ThemeManager.iconClose
                type: "icon"
            }
        }
    }
}
