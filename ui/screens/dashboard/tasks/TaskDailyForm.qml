import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.core
import qs.ui.shared

ColumnLayout {
    id: root

    property string dailyTitle: ""
    property string dailyNotes: ""
    property var dailyChecklist: []
    property date dailyStartDate: new Date()
    property string dailyRepeats: "daily"
    property int dailyRepeatEvery: 1
    property string dailyDifficulty: "easy"
    property var dailyTags: []
    
    signal requestDatePicker(var current, var callback)
    signal saved()

    spacing: 15
    Layout.fillWidth: true

    TextField {
        id: titleIn
        Layout.fillWidth: true
        height: 36
        placeholderText: "Daily Task Title"
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
            root.dailyTitle = text
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
            root.dailyNotes = text
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
            model: root.dailyChecklist
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
                            let list = [...root.dailyChecklist]
                            list.splice(index, 1)
                            root.dailyChecklist = list 
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
                        root.dailyChecklist = [
                            ...root.dailyChecklist, 
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

    RowLayout {
        Layout.fillWidth: true
        spacing: 15
        
        ColumnLayout {
            spacing: 6
            Layout.fillWidth: true
            StyledLabel { 
                text: "Start Date"
                type: "caption"
                opacity: 0.5 
            }
            
            BaseButton {
                Layout.fillWidth: true
                height: 36
                cornerRadius: 8
                onClicked: {
                    root.requestDatePicker(root.dailyStartDate, function(date) {
                        root.dailyStartDate = date
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
                    text: root.dailyStartDate.toLocaleDateString(Qt.locale(), "dd MMM yyyy")
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
                        let idx = items.indexOf(root.dailyDifficulty)
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
                            onClicked: root.dailyDifficulty = modelData
                            StyledLabel {
                                anchors.centerIn: parent
                                text: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                                font.pixelSize: 10
                                color: root.dailyDifficulty === modelData ? ThemeManager.contentPrimaryColor : "white"
                            }
                        }
                    }
                }
            }
        }
    }

    ColumnLayout {
        spacing: 6
        Layout.fillWidth: true
        StyledLabel { 
            text: "Repeats"
            type: "caption"
            opacity: 0.5 
        }
        Item {
            Layout.fillWidth: true
            height: 32
            SelectionPill {
                width: (parent.width - 18) / 4
                height: 32
                radius: 8
                x: { 
                    let items = ["daily", "weekly", "monthly", "yearly"]
                    let idx = items.indexOf(root.dailyRepeats)
                    return idx * (width + 6) 
                }
            }
            RowLayout {
                anchors.fill: parent
                spacing: 6
                z: 1
                Repeater {
                    model: ["daily", "weekly", "monthly", "yearly"]
                    delegate: BaseButton {
                        Layout.fillWidth: true
                        height: 32
                        onClicked: root.dailyRepeats = modelData
                        StyledLabel { 
                            anchors.centerIn: parent
                            text: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                            type: "caption"
                            color: root.dailyRepeats === modelData ? ThemeManager.contentPrimaryColor : "white"
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
            if (root.dailyTitle !== "") {
                HabitManager.addDaily({ 
                    "title": root.dailyTitle, 
                    "notes": root.dailyNotes, 
                    "checklist": root.dailyChecklist, 
                    "startDate": root.dailyStartDate.toLocaleDateString(), 
                    "repeats": root.dailyRepeats, 
                    "repeatEvery": root.dailyRepeatEvery, 
                    "difficulty": root.dailyDifficulty, 
                    "tags": root.dailyTags 
                })
                root.dailyTitle = ""
                root.dailyNotes = ""
                root.dailyChecklist = []
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
            text: "Save Daily"
            font.weight: Font.Bold
            color: ThemeManager.contentPrimaryColor 
        }
    }
}
