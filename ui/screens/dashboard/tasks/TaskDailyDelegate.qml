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
        return dailyInner.implicitHeight + 24
    }
    
    backgroundColor: {
        if (root.taskData && !!root.taskData.completed) {
            return Qt.rgba(0.3, 1, 0.3, 0.05)
        }
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
                icon: {
                    if (root.taskData && !!root.taskData.completed) {
                        return "󰄲"
                    }
                    return "󰄱"
                }
                color: {
                    if (root.taskData && !!root.taskData.completed) {
                        return "#4CAF50"
                    }
                    return ThemeManager.accentColor
                }
                onClicked: {
                    HabitManager.toggleDaily(root.taskIndex)
                    SoundManager.playClick()
                }
            }

            ColumnLayout {
                id: dailyInner
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
                        font.strikeout: {
                            if (!root.taskData) {
                                return false
                            }
                            return !!root.taskData.completed
                        }
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

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    visible: {
                        if (!root.taskData) {
                            return false
                        }
                        return !!root.taskData.checklist && root.taskData.checklist.count > 0
                    }

                    Repeater {
                        model: {
                            return root.taskData ? root.taskData.checklist : null
                        }
                        
                        delegate: BaseButton {
                            Layout.fillWidth: true
                            height: 20
                            onClicked: {
                                HabitManager.toggleDailyChecklistItem(root.taskIndex, index)
                                SoundManager.playClick()
                            }

                            RowLayout {
                                anchors.fill: parent
                                spacing: 8

                                Text {
                                    text: {
                                        return !!model.completed ? "󰄲" : "󰄱"
                                    }
                                    color: {
                                        return !!model.completed ? "#4CAF50" : ThemeManager.accentColor
                                    }
                                    font.pixelSize: 12
                                    opacity: {
                                        return !!model.completed ? 1.0 : 0.6
                                    }
                                }

                                StyledLabel {
                                    text: {
                                        return String(model.title || "")
                                    }
                                    type: "body"
                                    font.pixelSize: 10
                                    font.strikeout: {
                                        return !!model.completed
                                    }
                                    opacity: {
                                        return !!model.completed ? 0.5 : 0.8
                                    }
                                    Layout.fillWidth: true
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
                            if (!root.taskData) {
                                return ""
                            }
                            let repeats = String(root.taskData.repeats || "").toUpperCase()
                            let every = String(root.taskData.repeatEvery || 1)
                            return repeats + " • Every " + every
                        }
                        type: "caption"
                        opacity: 0.4 
                        font.pixelSize: 9
                    }
                }
            }

            TaskActionColumn {
                icon: "-"
                color: "#F44336"
                isVisible: true
                onClicked: {
                    HabitManager.removeDaily(root.taskIndex)
                    SoundManager.playClick()
                }
            }
        }
    }
}
