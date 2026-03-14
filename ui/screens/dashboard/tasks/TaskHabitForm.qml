import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.core
import qs.ui.shared

ColumnLayout {
    id: root

    property string habitTitle: ""
    property string habitNotes: ""
    property bool habitIsPositive: true
    property string habitDifficulty: "easy"
    property string habitReset: "daily"
    property var habitTags: []
    
    signal saved()

    spacing: 15
    Layout.fillWidth: true

    TextField {
        id: titleIn
        Layout.fillWidth: true
        height: 36
        placeholderText: "Habit Title"
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
            root.habitTitle = text
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
            root.habitNotes = text
        }
    }

    ColumnLayout {
        spacing: 6
        Layout.fillWidth: true
        StyledLabel { 
            text: "Reset Counter"
            type: "caption"
            opacity: 0.5 
        }
        
        Item {
            Layout.fillWidth: true
            height: 32

            SelectionPill {
                width: {
                    return (parent.width - (6 * 2)) / 3
                }
                height: parent.height
                radius: 8
                x: {
                    let items = ["daily", "weekly", "monthly"]
                    let idx = items.indexOf(root.habitReset)
                    return idx * (width + 6)
                }
            }

            RowLayout {
                anchors.fill: parent
                spacing: 6
                z: 1
                Repeater {
                    model: ["daily", "weekly", "monthly"]
                    delegate: BaseButton {
                        Layout.fillWidth: true
                        height: 32
                        onClicked: {
                            root.habitReset = modelData
                        }
                        StyledLabel { 
                            anchors.centerIn: parent
                            text: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                            type: "caption"
                            color: {
                                if (root.habitReset === modelData) {
                                    return ThemeManager.contentPrimaryColor
                                }
                                return "white"
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
            text: "Polarity"
            type: "caption"
            opacity: 0.5 
        }
        
        Item {
            Layout.fillWidth: true
            height: 32

            SelectionPill {
                width: {
                    return (parent.width - 10) / 2
                }
                height: parent.height
                radius: 8
                color: {
                    if (root.habitIsPositive) {
                        return "#4CAF50"
                    }
                    return "#F44336"
                }
                x: {
                    if (root.habitIsPositive) {
                        return 0
                    }
                    return width + 10
                }
                
                Behavior on color { 
                    ColorAnimation { 
                        duration: 200 
                    } 
                }
            }

            RowLayout {
                anchors.fill: parent
                spacing: 10
                z: 1
                BaseButton {
                    Layout.fillWidth: true
                    height: 32
                    onClicked: {
                        root.habitIsPositive = true
                    }
                    RowLayout { 
                        anchors.centerIn: parent
                        spacing: 6 
                        Text { 
                            text: "󰐕"
                            color: {
                                if (root.habitIsPositive) {
                                    return ThemeManager.contentPrimaryColor
                                }
                                return "white"
                            }
                            font.pixelSize: 14 
                        }
                        StyledLabel { 
                            text: "Positive"
                            type: "caption"
                            color: {
                                if (root.habitIsPositive) {
                                    return ThemeManager.contentPrimaryColor
                                }
                                return "white"
                            }
                        }
                    }
                }
                BaseButton {
                    Layout.fillWidth: true
                    height: 32
                    onClicked: {
                        root.habitIsPositive = false
                    }
                    RowLayout { 
                        anchors.centerIn: parent
                        spacing: 6 
                        Text { 
                            text: "-"
                            color: {
                                if (!root.habitIsPositive) {
                                    return ThemeManager.contentPrimaryColor
                                }
                                return "white"
                            }
                            font.pixelSize: 14 
                        }
                        StyledLabel { 
                            text: "Negative"
                            type: "caption"
                            color: {
                                if (!root.habitIsPositive) {
                                    return ThemeManager.contentPrimaryColor
                                }
                                return "white"
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
            text: "Difficulty"
            type: "caption"
            opacity: 0.5 
        }
        
        Item {
            Layout.fillWidth: true
            height: 28

            SelectionPill {
                width: {
                    return (parent.width - (6 * 3)) / 4
                }
                height: parent.height
                radius: 6
                x: {
                    let items = ["trivial", "easy", "medium", "hard"]
                    let idx = items.indexOf(
                        root.habitDifficulty
                    )
                    return idx * (width + 6)
                }
            }

            RowLayout {
                anchors.fill: parent
                spacing: 6
                z: 1
                Repeater {
                    model: ["trivial", "easy", "medium", "hard"]
                    delegate: BaseButton {
                        Layout.fillWidth: true
                        height: 28
                        onClicked: {
                            root.habitDifficulty = modelData
                        }
                        StyledLabel { 
                            anchors.centerIn: parent
                            text: {
                                return modelData.charAt(0).toUpperCase() + modelData.slice(1)
                            }
                            type: "caption"
                            color: {
                                if (root.habitDifficulty === modelData) {
                                    return ThemeManager.contentPrimaryColor
                                }
                                return "white"
                            }
                        }
                    }
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
                model: root.habitTags
                delegate: Rectangle {
                    width: {
                        return tagLabel.implicitWidth + 24
                    }
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
                                let tags = [...root.habitTags]
                                tags.splice(
                                    index, 
                                    1
                                )
                                root.habitTags = tags 
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
                id: habitTagIn
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
                    if (habitTagIn.text !== "") { 
                        root.habitTags = [
                            ...root.habitTags, 
                            habitTagIn.text
                        ]
                        HabitManager.addTag(
                            habitTagIn.text
                        )
                        habitTagIn.text = "" 
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
    }

    BaseButton {
        Layout.fillWidth: true
        height: 40
        cornerRadius: 10
        Layout.topMargin: 5
        onClicked: {
            if (root.habitTitle !== "") {
                HabitManager.addHabit({
                    "title": root.habitTitle, 
                    "notes": root.habitNotes,
                    "isPositive": root.habitIsPositive, 
                    "difficulty": root.habitDifficulty,
                    "resetCounter": root.habitReset,
                    "tags": root.habitTags
                })
                root.habitTitle = ""
                root.habitNotes = ""
                root.habitTags = []
                root.habitReset = "daily"
                titleIn.text = ""
                noteIn.text = ""
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
            text: "Save Habit"
            font.weight: Font.Bold
            color: ThemeManager.contentPrimaryColor 
        }
    }
}
