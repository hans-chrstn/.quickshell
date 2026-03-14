import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.core
import qs.ui.shared

ColumnLayout {
    id: root

    property var chronoEngine: null
    
    spacing: 15
    Layout.fillWidth: true
    Layout.fillHeight: true

    StyledLabel {
        text: "Pomodoro"
        type: "heading"
        font.pixelSize: 24
        Layout.alignment: Qt.AlignLeft
        Layout.bottomMargin: 5
    }

    StyledCard {
        Layout.fillWidth: true
        Layout.preferredHeight: 220

        ProgressRing {
            anchors.centerIn: parent
            width: 180
            height: 180
            strokeWidth: 8
            strokeColor: {
                if (root.chronoEngine && root.chronoEngine.pomodoroPhase === "work") {
                    return "#FF5252"
                }
                return "#4CAF50"
            }
            value: {
                if (!root.chronoEngine) {
                    return 0
                }
                
                let total = 0
                if (root.chronoEngine.pomodoroPhase === "work") {
                    total = root.chronoEngine.pomoWorkSeconds
                } else if (root.chronoEngine.pomodoroPhase === "shortBreak") {
                    total = root.chronoEngine.pomoShortBreakSeconds
                } else {
                    total = root.chronoEngine.pomoLongBreakSeconds
                }
                
                if (total <= 0) {
                    return 0
                }
                return 1.0 - (root.chronoEngine.countdownSeconds / total)
            }
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 5

            StyledLabel { 
                text: {
                    if (!root.chronoEngine) {
                        return "READY"
                    }
                    return String(root.chronoEngine.pomodoroPhase).toUpperCase()
                }
                type: "caption"
                Layout.alignment: Qt.AlignHCenter 
            }

            StyledLabel { 
                text: {
                    if (!root.chronoEngine) {
                        return "25:00"
                    }
                    return root.chronoEngine.getFormattedTime(root.chronoEngine.countdownSeconds)
                }
                font.pixelSize: 48
                font.weight: Font.Black
                font.family: "Monospace" 
                Layout.alignment: Qt.AlignHCenter
            }

            StyledLabel {
                text: {
                    let count = root.chronoEngine ? root.chronoEngine.completedPomodoros : 0
                    return "Done: " + count
                }
                type: "caption"
                color: ThemeManager.contentOnBackgroundColor
                opacity: 0.4
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 12
        
        BaseButton {
            Layout.fillWidth: true
            height: 50
            cornerRadius: 12

            onClicked: {
                if (root.chronoEngine) {
                    root.chronoEngine.startPomodoroEngine()
                }
            }

            Rectangle { 
                anchors.fill: parent
                radius: 12
                color: ThemeManager.accentColor 
            }

            StyledLabel { 
                anchors.centerIn: parent
                text: "Start Session"
                font.weight: Font.Bold
                color: ThemeManager.contentPrimaryColor 
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            radius: 12
            color: ThemeManager.surfaceSubtleColor
            
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                spacing: 15

                StyledLabel { 
                    text: "Auto Focus Mode"
                    type: "body" 
                    color: ThemeManager.contentOnBackgroundColor
                    Layout.alignment: Qt.AlignVCenter
                }

                Item { 
                    Layout.fillWidth: true 
                }

                Switch {
                    Layout.alignment: Qt.AlignVCenter
                    checked: {
                        return root.chronoEngine ? root.chronoEngine.autoFocusMode : false
                    }

                    onPositionChanged: {
                        if (down && root.chronoEngine) {
                            root.chronoEngine.autoFocusMode = checked
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Layout.topMargin: 5

            Repeater {
                model: [
                    { label: "Work", type: "work" },
                    { label: "Short", type: "short" },
                    { label: "Long", type: "long" }
                ]

                delegate: ColumnLayout {
                    spacing: 4
                    Layout.fillWidth: true
                    
                    readonly property int secondsValue: {
                        if (!root.chronoEngine) return 0
                        if (modelData.type === "work") return root.chronoEngine.pomoWorkSeconds
                        if (modelData.type === "short") return root.chronoEngine.pomoShortBreakSeconds
                        return root.chronoEngine.pomoLongBreakSeconds
                    }

                    StyledLabel { 
                        text: modelData.label
                        type: "caption"
                        opacity: 0.5
                        Layout.alignment: Qt.AlignHCenter 
                    }
                    
                    Rectangle {
                        Layout.fillWidth: true
                        height: 32
                        radius: 8
                        color: Qt.rgba(1, 1, 1, 0.05)
                        
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 4
                            spacing: 0
                            
                            BaseButton {
                                width: 24
                                height: 24
                                cornerRadius: 6

                                onClicked: {
                                    if (root.chronoEngine) {
                                        let val = Math.max(60, parent.parent.parent.secondsValue - 60)
                                        if (modelData.type === "work") {
                                            root.chronoEngine.pomoWorkSeconds = val
                                        } else if (modelData.type === "short") {
                                            root.chronoEngine.pomoShortBreakSeconds = val
                                        } else {
                                            root.chronoEngine.pomoLongBreakSeconds = val
                                        }
                                    }
                                }

                                Text { 
                                    anchors.centerIn: parent
                                    text: "-"
                                    font.pixelSize: 18
                                    color: "white"
                                    opacity: 0.5 
                                }
                            }
                            
                            StyledLabel { 
                                text: Math.floor(parent.parent.parent.secondsValue / 60) + "m"
                                type: "label"
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                            }
                            
                            BaseButton {
                                width: 24
                                height: 24
                                cornerRadius: 6

                                onClicked: {
                                    if (root.chronoEngine) {
                                        let val = parent.parent.parent.secondsValue + 60
                                        if (modelData.type === "work") {
                                            root.chronoEngine.pomoWorkSeconds = val
                                        } else if (modelData.type === "short") {
                                            root.chronoEngine.pomoShortBreakSeconds = val
                                        } else {
                                            root.chronoEngine.pomoLongBreakSeconds = val
                                        }
                                    }
                                }

                                Text { 
                                    anchors.centerIn: parent
                                    text: "󰐕"
                                    font.pixelSize: 12
                                    color: "white"
                                    opacity: 0.5 
                                }
                            }
                        }
                    }
                }
            }
        }

        StyledLabel {
            text: "Focus Tasks"
            type: "caption"
            opacity: 0.5
            Layout.topMargin: 10
        }

        ListView {
            id: pomoTaskList
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 150
            model: {
                return root.chronoEngine ? root.chronoEngine.pomoTaskStore : null
            }
            spacing: 8
            clip: true

            delegate: Rectangle {
                width: ListView.view.width
                height: 40
                radius: 8
                color: {
                    if (model.completed) {
                        return Qt.rgba(1, 1, 1, 0.02)
                    }
                    return Qt.rgba(1, 1, 1, 0.05)
                }

                CheckBox {
                    id: pomoCheck
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    checked: !!model.completed
                    
                    onToggled: {
                        if (root.chronoEngine) {
                            root.chronoEngine.togglePomoTask(index)
                        }
                    }
                }

                StyledLabel {
                    id: pomoLabel
                    text: String(model.label || "")
                    type: "body"
                    font.pixelSize: 13
                    font.strikeout: !!model.completed
                    opacity: model.completed ? 0.4 : 1.0
                    color: ThemeManager.contentOnBackgroundColor
                    
                    anchors.left: pomoCheck.right
                    anchors.leftMargin: 8
                    anchors.right: pomoDelete.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }

                BaseButton {
                    id: pomoDelete
                    width: 28
                    height: 28
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter

                    onClicked: {
                        if (root.chronoEngine) {
                            root.chronoEngine.removePomoTask(index)
                        }
                    }

                    Text { 
                        anchors.centerIn: parent
                        text: "󰅖"
                        color: "red"
                        opacity: 0.4
                        font.pixelSize: 14 
                    }
                }
            }

            header: Item {
                width: ListView.view ? ListView.view.width : 0
                height: 40
                
                RowLayout {
                    anchors.top: parent.top
                    width: parent.width
                    spacing: 8
                    
                    TextField {
                        id: pomoTaskIn
                        Layout.fillWidth: true
                        height: 32
                        placeholderText: "Quick task for this session..."
                        color: ThemeManager.contentOnBackgroundColor
                        placeholderTextColor: Qt.rgba(1, 1, 1, 0.4)
                        font.pixelSize: 12
                        leftPadding: 10
                        
                        background: Rectangle { 
                            radius: 6
                            color: Qt.rgba(0, 0, 0, 0.2) 
                        }
                    }

                    BaseButton {
                        width: 32
                        height: 32
                        cornerRadius: 6

                        onClicked: {
                            if (root.chronoEngine && pomoTaskIn.text !== "") {
                                root.chronoEngine.addPomoTask(pomoTaskIn.text)
                                pomoTaskIn.text = ""
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
        }
    }
}
