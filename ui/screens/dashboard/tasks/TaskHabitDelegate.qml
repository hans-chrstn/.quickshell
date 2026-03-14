import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.core
import qs.ui.shared

StyledCard {
    id: root

    property var taskData: null
    property int taskIndex: -1
    
    width: {
        return parent ? parent.width : 0
    }
    
    implicitHeight: {
        return habitInner.implicitHeight + 24
    }
    
    backgroundColor: {
        return Qt.rgba(1, 1, 1, 0.03)
    }
    
    ClippingRectangle {
        anchors.fill: parent
        radius: ThemeManager.globalCornerRadius
        color: "transparent"
        
        RowLayout {
            anchors.fill: parent
            spacing: 0

            TaskActionColumn {
                icon: "󰐕"
                color: "#4CAF50"
                isVisible: true
                onClicked: {
                    HabitManager.incrementHabit(root.taskIndex)
                    SoundManager.playClick()
                }
            }

            ColumnLayout {
                id: habitInner
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: 12
                spacing: 8

                ColumnLayout { 
                    spacing: 4
                    Layout.fillWidth: true

                    StyledLabel { 
                        text: {
                            if (!root.taskData) {
                                return ""
                            }
                            return String(root.taskData.title || "")
                        }
                        type: "title"
                        font.pixelSize: 15
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    StyledLabel { 
                        text: {
                            if (!root.taskData) {
                                return ""
                            }
                            return String(root.taskData.notes || "")
                        }
                        type: "caption"
                        opacity: 0.5
                        visible: {
                            if (!root.taskData) {
                                return false
                            }
                            return !!root.taskData.notes && root.taskData.notes !== ""
                        }
                        wrapMode: Text.WordWrap
                        font.pixelSize: 11
                        Layout.fillWidth: true
                    }
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: 4
                    visible: {
                        if (!root.taskData || !root.taskData.tags) {
                            return false
                        }
                        return root.taskData.tags.count > 0
                    }
                    
                    Repeater {
                        model: {
                            if (!root.taskData || !root.taskData.tags) {
                                return null
                            }
                            return root.taskData.tags
                        }
                        
                        delegate: Rectangle {
                            width: {
                                return tIcon.width + tLabel.implicitWidth + 12
                            }
                            height: 18
                            radius: 4
                            color: Qt.rgba(1, 1, 1, 0.05)
                            
                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 4
                                
                                Text {
                                    id: tIcon
                                    text: "󰓹"
                                    color: ThemeManager.accentColor
                                    font.pixelSize: 10
                                    opacity: 0.7
                                }
                                
                                StyledLabel {
                                    id: tLabel
                                    text: {
                                        return String(model.name || "")
                                    }
                                    type: "caption"
                                    font.pixelSize: 9
                                    opacity: 0.8
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    spacing: 10
                    
                    RowLayout {
                        spacing: 6
                        
                        Text { 
                            text: "󰈸"
                            color: "#FF5722"
                            font.pixelSize: 14 
                        }
                        
                        StyledLabel { 
                            text: {
                                if (!root.taskData) {
                                    return "0"
                                }
                                return String(root.taskData.streak || 0)
                            }
                            type: "caption"
                            font.weight: Font.Bold 
                        }
                    }

                    StyledLabel {
                        text: {
                            let count = root.taskData ? (root.taskData.counter || 0) : 0
                            return "Counter: " + count
                        }
                        type: "caption"
                        opacity: 0.4
                        font.pixelSize: 10
                    }
                }
            }

            TaskActionColumn {
                icon: "-"
                color: "#F44336"
                isVisible: true
                onClicked: {
                    HabitManager.decrementHabit(root.taskIndex)
                    SoundManager.playClick()
                }
            }
        }
    }
}
