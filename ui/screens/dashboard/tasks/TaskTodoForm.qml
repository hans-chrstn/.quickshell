import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.core
import qs.ui.shared

ColumnLayout {
    id: root

    property string todoTitle: ""
    property string todoNotes: ""
    property var todoChecklist: []
    property string todoDifficulty: "easy"
    property var todoTags: []
    property date todoDueDate: new Date()
    
    signal requestDatePicker(var current, var callback)
    signal saved()

    spacing: 15
    Layout.fillWidth: true

    TextField {
        id: titleIn
        Layout.fillWidth: true
        height: 36
        placeholderText: "To-Do Title"
        color: ThemeManager.contentOnBackgroundColor
        placeholderTextColor: Qt.rgba(1, 1, 1, 0.4)
        leftPadding: 10
        background: Rectangle { 
            radius: 8
            color: Qt.rgba(0, 0, 0, 0.3)
            border.color: {
                if (titleIn.activeFocus) {
                    return ThemeManager.accentColor
                }
                return Qt.rgba(1, 1, 1, 0.1)
            }
            border.width: 1
        }
        onTextChanged: {
            root.todoTitle = text
        }
    }

    TextField {
        id: noteIn
        Layout.fillWidth: true
        height: 36
        placeholderText: "Notes (Optional)"
        color: ThemeManager.contentOnBackgroundColor
        placeholderTextColor: Qt.rgba(1, 1, 1, 0.4)
        leftPadding: 10
        background: Rectangle { 
            radius: 8
            color: Qt.rgba(0, 0, 0, 0.3)
            border.color: {
                if (noteIn.activeFocus) {
                    return ThemeManager.accentColor
                }
                return Qt.rgba(1, 1, 1, 0.1)
            }
            border.width: 1
        }
        onTextChanged: {
            root.todoNotes = text
        }
    }

    ColumnLayout {
        spacing: 6
        Layout.fillWidth: true
        StyledLabel { 
            text: "Checklist"
            type: "caption"
            opacity: 0.5 
        }
        
        Repeater {
            model: root.todoChecklist
            delegate: Rectangle {
                width: root.width
                height: 36
                radius: 8
                color: Qt.rgba(1, 1, 1, 0.05)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 10

                    Text {
                        text: "󰄱"
                        color: ThemeManager.accentColor
                        font.pixelSize: 14
                        opacity: 0.6
                    }

                    StyledLabel { 
                        text: modelData.title
                        type: "body"
                        font.pixelSize: 12
                        Layout.fillWidth: true 
                        elide: Text.ElideRight
                    }

                    BaseButton { 
                        width: 24
                        height: 24
                        onClicked: { 
                            let list = [...root.todoChecklist]
                            list.splice(index, 1)
                            root.todoChecklist = list 
                        }
                        Text { 
                            anchors.centerIn: parent
                            text: "󰅖"
                            color: "red"
                            opacity: 0.5
                            font.pixelSize: 12 
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            TextField {
                id: checkIn
                Layout.fillWidth: true
                height: 30
                placeholderText: "Add item..."
                font.pixelSize: 11
                color: ThemeManager.contentOnBackgroundColor
                placeholderTextColor: Qt.rgba(1, 1, 1, 0.4)
                background: Rectangle { 
                    radius: 6
                    color: Qt.rgba(1, 1, 1, 0.05) 
                }
            }
            BaseButton {
                width: 30
                height: 30
                cornerRadius: 6
                onClicked: { 
                    if (checkIn.text !== "") { 
                        root.todoChecklist = [
                            ...root.todoChecklist, 
                            { "title": checkIn.text, "completed": false }
                        ]
                        checkIn.text = "" 
                    } 
                }
                Rectangle { 
                    anchors.fill: parent
                    radius: 6
                    color: ThemeManager.accentColor 
                }
                Text { 
                    anchors.centerIn: parent
                    text: "󰐕"
                    color: ThemeManager.contentPrimaryColor 
                }
            }
        }
    }

    ColumnLayout {
        spacing: 8
        Layout.fillWidth: true
        StyledLabel { 
            text: "Tags"
            type: "caption"
            opacity: 0.5 
        }
        Flow {
            Layout.fillWidth: true
            spacing: 6
            Repeater {
                model: root.todoTags
                delegate: Rectangle {
                    width: tagLabel.implicitWidth + 24
                    height: 24
                    radius: 12
                    color: Qt.rgba(1, 1, 1, 0.05)
                    border.color: Qt.rgba(1, 1, 1, 0.1)
                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        StyledLabel { 
                            id: tagLabel
                            text: modelData
                            type: "caption"
                            font.pixelSize: 10 
                        }
                        BaseButton {
                            width: 14
                            height: 14
                            onClicked: { 
                                let tags = [...root.todoTags]
                                tags.splice(index, 1)
                                root.todoTags = tags 
                            }
                            Text { 
                                anchors.centerIn: parent
                                text: "󰅖"
                                color: "red"
                                font.pixelSize: 8
                                opacity: 0.6 
                            }
                        }
                    }
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            TextField {
                id: todoTagIn
                Layout.fillWidth: true
                height: 30
                placeholderText: "Add tag..."
                font.pixelSize: 11
                color: ThemeManager.contentOnBackgroundColor
                placeholderTextColor: Qt.rgba(1, 1, 1, 0.4)
                background: Rectangle { 
                    radius: 6
                    color: Qt.rgba(1, 1, 1, 0.05) 
                }
            }
            BaseButton {
                width: 30
                height: 30
                cornerRadius: 6
                onClicked: { 
                    if (todoTagIn.text !== "") { 
                        root.todoTags = [
                            ...root.todoTags, 
                            todoTagIn.text
                        ]
                        HabitManager.addTag(todoTagIn.text)
                        todoTagIn.text = "" 
                    } 
                }
                Rectangle { 
                    anchors.fill: parent
                    radius: 6
                    color: ThemeManager.surfaceSubtleColor 
                }
                Text { 
                    anchors.centerIn: parent
                    text: "󰐕"
                    color: "white"
                    opacity: 0.7 
                }
            }
        }

        StyledLabel { 
            text: "Available Tags"
            type: "caption"
            opacity: 0.3
            font.pixelSize: 9
            Layout.topMargin: 5
            visible: {
                return HabitManager.tagStore.count > 0
            }
        }

        Flow {
            Layout.fillWidth: true
            spacing: 6
            Repeater {
                model: HabitManager.tagStore
                delegate: Rectangle {
                    width: availTagLabel.implicitWidth + 28
                    height: 22
                    radius: 11
                    color: Qt.rgba(1, 1, 1, 0.03)
                    border.color: Qt.rgba(1, 1, 1, 0.05)
                    
                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6
                        
                        BaseButton {
                            Layout.preferredWidth: availTagLabel.implicitWidth
                            Layout.fillHeight: true
                            onClicked: {
                                let tagName = String(model.name || "")
                                if (!root.todoTags.includes(tagName)) {
                                    root.todoTags = [...root.todoTags, tagName]
                                }
                            }
                            StyledLabel {
                                id: availTagLabel
                                text: String(model.name || "")
                                type: "caption"
                                font.pixelSize: 9
                                opacity: 0.6
                            }
                        }

                        BaseButton {
                            width: 12
                            height: 12
                            onClicked: {
                                HabitManager.removeTag(index)
                            }
                            Text {
                                anchors.centerIn: parent
                                text: "󰅖"
                                color: "red"
                                font.pixelSize: 7
                                opacity: 0.4
                            }
                        }
                    }
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 15
        
        ColumnLayout {
            spacing: 6
            Layout.fillWidth: true
            StyledLabel { 
                text: "Due Date"
                type: "caption"
                opacity: 0.5 
            }
            
            BaseButton {
                Layout.fillWidth: true
                height: 36
                cornerRadius: 8
                onClicked: {
                    root.requestDatePicker(root.todoDueDate, function(date) {
                        root.todoDueDate = date
                    })
                }
                Rectangle { 
                    anchors.fill: parent
                    radius: 8
                    color: Qt.rgba(0, 0, 0, 0.3)
                    border.color: Qt.rgba(1, 1, 1, 0.1)
                    border.width: 1
                }
                StyledLabel {
                    anchors.centerIn: parent
                    text: root.todoDueDate.toLocaleDateString(Qt.locale(), "dd MMM yyyy")
                    type: "body"
                    font.pixelSize: 12
                }
            }
        }

        ColumnLayout {
            spacing: 6
            Layout.fillWidth: true
            StyledLabel { 
                text: "Difficulty"
                type: "caption"
                opacity: 0.5 
            }
            Item {
                Layout.fillWidth: true
                height: 36
                SelectionPill {
                    width: (parent.width - 12) / 3
                    height: 36
                    radius: 8
                    x: {
                        let items = ["easy", "medium", "hard"]
                        let idx = items.indexOf(root.todoDifficulty)
                        return idx * (width + 6)
                    }
                }
                RowLayout {
                    anchors.fill: parent
                    spacing: 6
                    z: 1
                    Repeater {
                        model: ["easy", "medium", "hard"]
                        delegate: BaseButton {
                            Layout.fillWidth: true
                            height: 36
                            onClicked: root.todoDifficulty = modelData
                            StyledLabel {
                                anchors.centerIn: parent
                                text: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                                font.pixelSize: 10
                                color: root.todoDifficulty === modelData ? ThemeManager.contentPrimaryColor : "white"
                            }
                        }
                    }
                }
            }
        }
    }

    BaseButton {
        Layout.fillWidth: true
        height: 44
        cornerRadius: 10
        onClicked: {
            if (root.todoTitle !== "") {
                HabitManager.addTodo({ 
                    "title": root.todoTitle, 
                    "notes": root.todoNotes, 
                    "checklist": root.todoChecklist, 
                    "difficulty": root.todoDifficulty, 
                    "dueDate": root.todoDueDate.toLocaleDateString(),
                    "tags": root.todoTags 
                })
                root.todoTitle = ""
                root.todoNotes = ""
                root.todoChecklist = []
                root.todoTags = []
                root.saved()
                SoundManager.playSuccess()
            }
        }
        Rectangle { 
            anchors.fill: parent
            radius: 10
            color: ThemeManager.accentColor 
        }
        StyledLabel { 
            anchors.centerIn: parent
            text: "Save To-Do"
            font.weight: Font.Bold
            color: ThemeManager.contentPrimaryColor 
        }
    }
}
