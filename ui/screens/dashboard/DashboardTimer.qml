import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.core
import qs.ui.shared
import qs.ui.screens.dashboard.calendar

ColumnLayout {
    anchors.fill: parent
    anchors.margins: 30
    spacing: 25

    StyledLabel {
        text: "Timers & Alarms"
        type: "heading"
        font.pixelSize: 28
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 12

        Repeater {
            model: ["Timer", "Alarm"]
            delegate: BaseButton {
                Layout.fillWidth: true
                height: 40
                cornerRadius: 10
                
                readonly property bool isSelected: TimerManager.mode === modelData.toLowerCase()

                onClicked: {
                    TimerManager.mode = modelData.toLowerCase()
                    SoundManager.playClick()
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 10
                    color: parent.isSelected 
                        ? ThemeManager.accentColor 
                        : (parent.isHovered ? ThemeManager.surfaceStrongColor : ThemeManager.surfacePrimaryColor)
                    border.color: ThemeManager.outlineVariantColor
                    border.width: 1
                }

                StyledLabel {
                    anchors.centerIn: parent
                    text: modelData
                    type: "button"
                    color: parent.isSelected ? ThemeManager.contentPrimaryColor : ThemeManager.contentOnBackgroundColor
                }
            }
        }
    }

    StyledCard {
        Layout.fillWidth: true
        Layout.preferredHeight: 180
        visible: TimerManager.mode === "timer"

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 15

            StyledLabel {
                text: TimerManager.formatTime(TimerManager.remainingSeconds)
                type: "heading"
                font.pixelSize: 64
                font.weight: Font.Black
                font.family: "Monospace"
                Layout.alignment: Qt.AlignHCenter
                color: TimerManager.running ? ThemeManager.accentColor : ThemeManager.contentOnBackgroundColor
            }

            RowLayout {
                spacing: 15
                Layout.alignment: Qt.AlignHCenter

                BaseButton {
                    width: 44
                    height: 44
                    cornerRadius: 22
                    onClicked: TimerManager.togglePause()

                    Rectangle {
                        anchors.fill: parent
                        radius: 22
                        color: ThemeManager.surfaceStrongColor
                    }

                    Text {
                        anchors.centerIn: parent
                        text: TimerManager.running ? "󰏤" : "󰐊"
                        color: "#FFFFFF"
                        font.pixelSize: 20
                    }
                }

                BaseButton {
                    width: 44
                    height: 44
                    cornerRadius: 22
                    onClicked: TimerManager.reset()

                    Rectangle {
                        anchors.fill: parent
                        radius: 22
                        color: ThemeManager.surfaceStrongColor
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "󰕌"
                        color: "#FFFFFF"
                        font.pixelSize: 18
                    }
                }
            }
        }
    }

    StyledCard {
        Layout.fillWidth: true
        Layout.fillHeight: true
        
        StackLayout {
            anchors.fill: parent
            anchors.margins: 20
            currentIndex: TimerManager.mode === "timer" ? 0 : 1

            Grid {
                columns: 3
                spacing: 10
                Repeater {
                    model: [1, 5, 10, 15, 30, 60]
                    delegate: BaseButton {
                        width: (parent.width - 20) / 3
                        height: 60
                        cornerRadius: 8
                        onClicked: TimerManager.startTimer(modelData)

                        Rectangle {
                            anchors.fill: parent
                            radius: 8
                            color: ThemeManager.surfaceSubtleColor
                            border.color: ThemeManager.outlineVariantColor
                            border.width: 1
                        }

                        StyledLabel {
                            anchors.centerIn: parent
                            text: modelData + "m"
                            type: "title"
                        }
                    }
                }
            }

            ColumnLayout {
                spacing: 15
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    
                    TimePicker {
                        id: newAlarmPicker
                        Layout.preferredWidth: 100
                        height: 90
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        
                        TextField {
                            id: alarmTitleInput
                            Layout.fillWidth: true
                            placeholderText: "Alarm Title"
                            font.pixelSize: 13
                            color: "#FFFFFF"
                            padding: 10
                            background: Rectangle { 
                                radius: 8; 
                                color: Qt.rgba(0,0,0,0.3); 
                                border.color: alarmTitleInput.activeFocus ? ThemeManager.accentColor : Qt.rgba(1,1,1,0.1) 
                            }
                        }

                        BaseButton {
                            Layout.fillWidth: true
                            height: 36
                            cornerRadius: 8
                            onClicked: {
                                TimerManager.addAlarm(newAlarmPicker.time, alarmTitleInput.text)
                                alarmTitleInput.text = ""
                            }
                            Rectangle { anchors.fill: parent; radius: 8; color: ThemeManager.accentColor }
                            StyledLabel { anchors.centerIn: parent; text: "Add Alarm"; type: "button"; color: ThemeManager.contentPrimaryColor }
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: ThemeManager.outlineVariantColor; opacity: 0.2 }

                ListView {
                    id: alarmList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: TimerManager.alarms
                    spacing: 8
                    clip: true
                    
                    delegate: Item {
                        width: alarmList.width
                        height: 50
                        
                        Rectangle {
                            anchors.fill: parent
                            radius: 8
                            color: model.enabled ? ThemeManager.surfaceStrongColor : ThemeManager.surfaceSubtleColor
                            opacity: 0.6
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 12

                            ColumnLayout {
                                spacing: 0
                                Layout.fillWidth: true
                                StyledLabel { text: model.time; type: "title"; font.pixelSize: 16 }
                                StyledLabel { text: model.title; type: "caption"; opacity: 0.6 }
                            }

                            Switch {
                                checked: model.enabled
                                onPositionChanged: {
                                    if (down) TimerManager.toggleAlarm(index)
                                }
                            }

                            BaseButton {
                                width: 32; height: 32; cornerRadius: 6
                                onClicked: TimerManager.deleteAlarm(index)
                                Text { anchors.centerIn: parent; text: "󰆴"; color: "#FF4747"; font.pixelSize: 16; opacity: parent.isHovered ? 1.0 : 0.4 }
                            }
                        }
                    }
                }
            }
        }
    }
}
