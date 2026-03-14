import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.core
import qs.ui.shared

ColumnLayout {
    id: root

    property bool active: false
    property var chronoEngine: null
    property string activeTab: "timer"

    readonly property int targetIndex: {
        if (root.activeTab === "timer") return 0
        if (root.activeTab === "pomo") return 1
        return 2
    }

    anchors.fill: parent
    anchors.margins: 30
    spacing: 20

    Item {
        Layout.fillWidth: true
        height: 42

        Rectangle {
            id: selectionIndicator
            width: (parent.width - (10 * 2)) / 3
            height: parent.height
            radius: 10
            color: ThemeManager.accentColor
            z: 0
            x: root.targetIndex * (width + 10)

            Behavior on x {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutQuart
                }
            }
        }

        RowLayout {
            anchors.fill: parent
            spacing: 10
            z: 1

            Repeater {
                model: [
                    { id: "timer", label: "Timer", icon: "󰔛" },
                    { id: "pomo", label: "Pomo", icon: "󰄉" },
                    { id: "alarms", label: "Alarms", icon: "󰥔" }
                ]

                delegate: BaseButton {
                    Layout.fillWidth: true
                    height: 42 
                    cornerRadius: 10
                    
                    readonly property bool isSelected: root.activeTab === modelData.id

                    onClicked: {
                        root.activeTab = modelData.id
                        SoundManager.playClick()
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: 10
                        color: parent.isHovered ? ThemeManager.surfaceStrongColor : "transparent"
                        visible: !parent.isSelected
                        border.color: ThemeManager.outlineVariantColor
                        border.width: 1
                    }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            text: modelData.icon
                            font.pixelSize: 16
                            color: parent.parent.isSelected ? ThemeManager.contentPrimaryColor : ThemeManager.contentOnBackgroundColor
                            opacity: parent.parent.isSelected ? 1.0 : 0.6
                        }

                        StyledLabel {
                            text: modelData.label
                            type: "label"
                            font.weight: parent.parent.isSelected ? Font.DemiBold : Font.Normal
                            color: parent.parent.isSelected ? ThemeManager.contentPrimaryColor : ThemeManager.contentOnBackgroundColor
                        }
                    }
                }
            }
        }
    }

    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true

        ColumnLayout {
            anchors.fill: parent
            spacing: 20
            opacity: root.activeTab === "timer" ? 1.0 : 0.0
            visible: opacity > 0.01

            transform: Translate {
                x: root.activeTab === "timer" ? 0 : (root.targetIndex > 0 ? -40 : 40)
                Behavior on x { NumberAnimation { duration: 350; easing.type: Easing.OutQuart } }
            }
            Behavior on opacity { NumberAnimation { duration: 250 } }

            StyledCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 180

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 15

                    StyledLabel {
                        text: root.chronoEngine ? root.chronoEngine.getFormattedTime(root.chronoEngine.countdownSeconds) : "00:00"
                        type: "heading"
                        font.pixelSize: 64
                        font.weight: Font.Black
                        font.family: "Monospace"
                        Layout.alignment: Qt.AlignHCenter
                        color: (root.chronoEngine && root.chronoEngine.isCounting) ? ThemeManager.accentColor : ThemeManager.contentOnBackgroundColor
                    }

                    RowLayout {
                        spacing: 20
                        Layout.alignment: Qt.AlignHCenter

                        BaseButton {
                            width: 50; height: 50; cornerRadius: 25
                            onClicked: if (root.chronoEngine) root.chronoEngine.toggleExecution()
                            Rectangle { anchors.fill: parent; radius: 25; color: ThemeManager.surfaceStrongColor }
                            Text { anchors.centerIn: parent; text: (root.chronoEngine && root.chronoEngine.isCounting) ? "󰏤" : "󰐊"; color: "#FFFFFF"; font.pixelSize: 22 }
                        }

                        BaseButton {
                            width: 50; height: 50; cornerRadius: 25
                            onClicked: if (root.chronoEngine) root.chronoEngine.revertToLastStart()
                            Rectangle { anchors.fill: parent; radius: 25; color: ThemeManager.surfaceStrongColor }
                            Text { anchors.centerIn: parent; text: "󰕌"; color: "#FFFFFF"; font.pixelSize: 20 }
                        }

                        BaseButton {
                            width: 50; height: 50; cornerRadius: 25
                            onClicked: if (root.chronoEngine) root.chronoEngine.resetChronometer()
                            Rectangle { anchors.fill: parent; radius: 25; color: ThemeManager.surfaceStrongColor }
                            Text { anchors.centerIn: parent; text: "󰅖"; color: "#FFFFFF"; font.pixelSize: 20 }
                        }
                    }
                }
            }

            GridLayout {
                columns: 2
                rowSpacing: 10
                columnSpacing: 10
                Layout.fillWidth: true

                Repeater {
                    model: [
                        { label: "+1m", val: 60 },
                        { label: "+5m", val: 300 },
                        { label: "+10m", val: 600 },
                        { label: "-1m", val: -60 }
                    ]
                    delegate: BaseButton {
                        Layout.fillWidth: true
                        height: 50
                        cornerRadius: 12
                        onClicked: if (root.chronoEngine) root.chronoEngine.modifyCountdown(modelData.val)

                        Rectangle {
                            anchors.fill: parent
                            radius: 12
                            color: ThemeManager.surfaceSubtleColor
                            border.color: ThemeManager.outlineVariantColor
                            border.width: 1
                        }

                        StyledLabel {
                            anchors.centerIn: parent
                            text: modelData.label
                            type: "body"
                        }
                    }
                }
            }
            Item { Layout.fillHeight: true }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 20
            opacity: root.activeTab === "pomo" ? 1.0 : 0.0
            visible: opacity > 0.01

            transform: Translate {
                x: root.activeTab === "pomo" ? 0 : (root.targetIndex > 1 ? -40 : 40)
                Behavior on x { NumberAnimation { duration: 350; easing.type: Easing.OutQuart } }
            }
            Behavior on opacity { NumberAnimation { duration: 250 } }

            StyledCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 200

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 10

                    StyledLabel {
                        text: {
                            if (!root.chronoEngine) return "READY"
                            if (root.chronoEngine.pomodoroPhase === "work") return "FOCUS"
                            if (root.chronoEngine.pomodoroPhase === "shortBreak") return "BREAK"
                            if (root.chronoEngine.pomodoroPhase === "longBreak") return "LONG BREAK"
                            return "POMODORO"
                        }
                        type: "caption"
                        font.weight: Font.Black
                        font.letterSpacing: 2
                        opacity: 0.5
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledLabel {
                        text: root.chronoEngine ? root.chronoEngine.getFormattedTime(root.chronoEngine.countdownSeconds) : "25:00"
                        type: "heading"
                        font.pixelSize: 64
                        font.weight: Font.Black
                        font.family: "Monospace"
                        Layout.alignment: Qt.AlignHCenter
                    }

                    StyledLabel {
                        text: "Done: " + (root.chronoEngine ? root.chronoEngine.completedPomodoros : 0)
                        type: "caption"
                        opacity: 0.4
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }

            BaseButton {
                Layout.fillWidth: true
                height: 54
                cornerRadius: 12
                onClicked: if (root.chronoEngine) root.chronoEngine.startPomodoroEngine()

                Rectangle {
                    anchors.fill: parent
                    radius: 12
                    color: ThemeManager.accentColor
                }

                StyledLabel {
                    anchors.centerIn: parent
                    text: "Start Focus Session"
                    type: "button"
                    font.weight: Font.Bold
                    color: ThemeManager.contentPrimaryColor
                }
            }
            Item { Layout.fillHeight: true }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 20
            opacity: root.activeTab === "alarms" ? 1.0 : 0.0
            visible: opacity > 0.01

            transform: Translate {
                x: root.activeTab === "alarms" ? 0 : (root.targetIndex > 2 ? -40 : 40)
                Behavior on x { NumberAnimation { duration: 350; easing.type: Easing.OutQuart } }
            }
            Behavior on opacity { NumberAnimation { duration: 250 } }

            StyledCard {
                id: creatorCard
                Layout.fillWidth: true
                Layout.preferredHeight: 240

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 15

                    TimeScroller {
                        id: alarmPicker
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredHeight: 110
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        TextField {
                            id: alarmLabelInput
                            Layout.fillWidth: true
                            height: 40
                            placeholderText: "Label"
                            font.family: ThemeManager.fontFamily
                            color: ThemeManager.contentOnBackgroundColor
                            placeholderTextColor: Qt.rgba(1, 1, 1, 0.4)
                            selectedTextColor: ThemeManager.contentPrimaryColor
                            selectionColor: ThemeManager.accentColor
                            padding: 8
                            background: Rectangle {
                                radius: 8
                                color: Qt.rgba(0,0,0,0.3)
                                border.color: alarmLabelInput.activeFocus ? ThemeManager.accentColor : ThemeManager.outlinePrimaryColor
                                border.width: 1
                            }
                        }

                        BaseButton {
                            width: 70
                            height: 40
                            cornerRadius: 8
                            onClicked: {
                                if (root.chronoEngine) {
                                    root.chronoEngine.registerAlarm(alarmPicker.time, alarmLabelInput.text)
                                    alarmLabelInput.text = ""
                                }
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: 8
                                color: ThemeManager.accentColor
                            }

                            StyledLabel {
                                anchors.centerIn: parent
                                text: "Add"
                                type: "button"
                                font.weight: Font.Bold
                                color: ThemeManager.contentPrimaryColor
                            }
                        }
                    }
                }
            }

            ListView {
                id: alarmList
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: root.chronoEngine ? root.chronoEngine.alarmStore : null
                spacing: 10
                clip: true

                delegate: StyledCard {
                    width: alarmList.width
                    height: 75 
                    backgroundColor: model.active ? Qt.rgba(1,1,1,0.06) : ThemeManager.surfaceSubtleColor

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 15
                        spacing: 15

                        ColumnLayout {
                            spacing: 2
                            Layout.fillWidth: true

                            StyledLabel {
                                text: model.time
                                type: "title"
                                font.pixelSize: 20
                                opacity: model.active ? 1.0 : 0.4
                            }

                            StyledLabel {
                                text: model.label || "Alarm"
                                type: "caption"
                                opacity: model.active ? 0.6 : 0.2
                            }
                        }

                        Switch {
                            checked: model.active
                            onPositionChanged: {
                                if (down && root.chronoEngine) {
                                    root.chronoEngine.updateAlarmState(index, checked)
                                }
                            }
                        }

                        BaseButton {
                            width: 32
                            height: 32
                            cornerRadius: 16
                            onClicked: if (root.chronoEngine) root.chronoEngine.unregisterAlarm(index)

                            Rectangle {
                                anchors.fill: parent
                                radius: 16
                                color: parent.isHovered ? Qt.rgba(1,0,0,0.1) : "transparent"
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "󰅖"
                                color: parent.isHovered ? ThemeManager.dangerColor : ThemeManager.contentOnBackgroundColor
                                opacity: parent.isHovered ? 1.0 : 0.3
                                font.pixelSize: 16
                            }
                        }
                    }
                }
            }
        }
    }
}
