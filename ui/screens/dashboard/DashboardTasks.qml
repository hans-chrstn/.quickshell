import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import qs.core
import qs.ui.shared
import "./tasks"

Item {
    id: root

    property bool active: false
    property var chronoEngine: null
    
    property string activeTaskType: "habit"
    property bool isAddingTask: false
    
    property bool isDatePickerVisible: false
    property var datePickerCallback: null
    property date datePickerInitial: new Date()

    anchors.fill: parent

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 25
        spacing: 20

        RowLayout {
            Layout.fillWidth: true
            spacing: 15

            StyledLabel {
                text: "Tasks & Habits"
                type: "heading"
                font.pixelSize: 24
                Layout.fillWidth: true
            }

            BaseButton {
                width: 44
                height: 44
                cornerRadius: 22
                
                onClicked: {
                    root.isAddingTask = !root.isAddingTask
                    SoundManager.playClick()
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 22
                    color: {
                        if (root.isAddingTask) {
                            return ThemeManager.dangerColor
                        }
                        return ThemeManager.accentColor
                    }
                    opacity: {
                        if (root.isAddingTask) {
                            return 0.2
                        }
                        return 1.0
                    }
                    
                    Behavior on color { 
                        ColorAnimation { 
                            duration: 200 
                        } 
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: {
                        if (root.isAddingTask) {
                            return "󰅖"
                        }
                        return "󰐕"
                    }
                    font.pixelSize: 22
                    color: {
                        if (root.isAddingTask) {
                            return ThemeManager.dangerColor
                        }
                        return ThemeManager.contentPrimaryColor
                    }
                }
            }
        }

        Item {
            id: addPanelContainer
            Layout.fillWidth: true
            Layout.preferredHeight: {
                if (root.isAddingTask) {
                    return Math.min(
                        formColumn.implicitHeight + 40, 
                        650
                    )
                }
                return 0
            }
            clip: true
            opacity: {
                if (root.isAddingTask) {
                    return 1.0
                }
                return 0.0
            }
            
            visible: {
                return opacity > 0.001
            }

            Behavior on Layout.preferredHeight { 
                NumberAnimation { 
                    duration: 400
                    easing.type: Easing.OutExpo 
                } 
            }
            
            Behavior on opacity { 
                NumberAnimation { 
                    duration: 250 
                } 
            }

            StyledCard {
                anchors.fill: parent
                backgroundColor: ThemeManager.surfaceStrongColor

                Flickable {
                    anchors.fill: parent
                    contentWidth: width
                    contentHeight: formColumn.implicitHeight + 40
                    clip: true
                    interactive: true

                    ColumnLayout {
                        id: formColumn
                        width: {
                            return parent.width - 20
                        }
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: 20
                        spacing: 15

                        Item {
                            Layout.fillWidth: true
                            height: 32

                            SelectionPill {
                                width: {
                                    return (parent.width - (8 * 2)) / 3
                                }
                                height: parent.height
                                radius: 8
                                x: {
                                    let idx = 0
                                    if (root.activeTaskType === "daily") {
                                        idx = 1
                                    } else if (root.activeTaskType === "todo") {
                                        idx = 2
                                    }
                                    return idx * (width + 8)
                                }
                            }

                            RowLayout {
                                anchors.fill: parent
                                spacing: 8
                                z: 1

                                Repeater {
                                    model: [
                                        { id: "habit", label: "Habit" },
                                        { id: "daily", label: "Daily" },
                                        { id: "todo", label: "To-Do" }
                                    ]

                                    delegate: BaseButton {
                                        Layout.fillWidth: true
                                        height: 32
                                        cornerRadius: 8
                                        
                                        onClicked: {
                                            root.activeTaskType = modelData.id
                                            SoundManager.playClick()
                                        }

                                        StyledLabel {
                                            anchors.centerIn: parent
                                            text: modelData.label
                                            type: "label"
                                            font.pixelSize: 10
                                            color: {
                                                if (root.activeTaskType === modelData.id) {
                                                    return ThemeManager.contentPrimaryColor
                                                }
                                                return ThemeManager.contentOnBackgroundColor
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        TaskHabitForm {
                            visible: root.activeTaskType === "habit"
                            onSaved: root.isAddingTask = false
                        }

                        TaskDailyForm {
                            visible: root.activeTaskType === "daily"
                            onSaved: root.isAddingTask = false
                            onRequestDatePicker: (current, callback) => {
                                root.datePickerInitial = current
                                root.datePickerCallback = callback
                                root.isDatePickerVisible = true
                            }
                        }

                        TaskTodoForm {
                            visible: root.activeTaskType === "todo"
                            onSaved: root.isAddingTask = false
                            onRequestDatePicker: (current, callback) => {
                                root.datePickerInitial = current
                                root.datePickerCallback = callback
                                root.isDatePickerVisible = true
                            }
                        }
                    }
                }
            }
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: taskStack.implicitHeight
            clip: true
            interactive: true

            ColumnLayout {
                id: taskStack
                width: parent.width
                spacing: 25

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    StyledLabel {
                        text: "Habits"
                        type: "title"
                        font.weight: Font.Bold
                        opacity: 0.7
                    }
                    Repeater {
                        model: HabitManager.habitStore
                        delegate: TaskHabitDelegate {
                            taskData: model
                            taskIndex: index
                        }
                    }
                    StyledLabel {
                        text: "No habits tracked yet."
                        type: "caption"
                        opacity: 0.3
                        Layout.alignment: Qt.AlignHCenter
                        visible: {
                            return HabitManager.habitStore.count === 0
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    StyledLabel {
                        text: "Dailies"
                        type: "title"
                        font.weight: Font.Bold
                        opacity: 0.7
                    }
                    Repeater {
                        model: HabitManager.dailyStore
                        delegate: TaskDailyDelegate {
                            taskData: model
                            taskIndex: index
                        }
                    }
                    StyledLabel {
                        text: "All dailies complete for now."
                        type: "caption"
                        opacity: 0.3
                        Layout.alignment: Qt.AlignHCenter
                        visible: {
                            return HabitManager.dailyStore.count === 0
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    StyledLabel {
                        text: "To-Do's"
                        type: "title"
                        font.weight: Font.Bold
                        opacity: 0.7
                    }
                    Repeater {
                        model: HabitManager.todoStore
                        delegate: TaskTodoDelegate {
                            taskData: model
                            taskIndex: index
                        }
                    }
                    StyledLabel {
                        text: "No active to-do items."
                        type: "caption"
                        opacity: 0.3
                        Layout.alignment: Qt.AlignHCenter
                        visible: {
                            return HabitManager.todoStore.count === 0
                        }
                    }
                }
            }
        }
    }

    Item {
        id: datePickerOverlay
        anchors.fill: parent
        visible: root.isDatePickerVisible
        z: 100

        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: 0.5
            MouseArea {
                anchors.fill: parent
                onClicked: root.isDatePickerVisible = false
            }
        }

        CalendarPicker {
            anchors.centerIn: parent
            selectedDate: root.datePickerInitial
            onDateSelected: (date) => {
                if (root.datePickerCallback) {
                    root.datePickerCallback(date)
                }
                root.isDatePickerVisible = false
            }
            onClosed: root.isDatePickerVisible = false
        }
    }
}
