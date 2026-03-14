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
        text: "Alarms"
        type: "heading"
        font.pixelSize: 24
        Layout.alignment: Qt.AlignLeft
        Layout.bottomMargin: 5
    }

    StyledCard {
        Layout.fillWidth: true
        Layout.preferredHeight: 220

        ColumnLayout { 
            anchors.fill: parent
            anchors.margins: 15
            spacing: 15

            TimeScroller { 
                id: alarmPicker
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredHeight: 100 
            }

            RowLayout { 
                Layout.fillWidth: true
                spacing: 8

                TextField { 
                    id: alarmIn
                    Layout.fillWidth: true
                    height: 40
                    placeholderText: "Label"
                    color: ThemeManager.contentOnBackgroundColor
                    placeholderTextColor: Qt.rgba(1, 1, 1, 0.4)
                    leftPadding: 12
                    
                    background: Rectangle { 
                        radius: 8
                        color: Qt.rgba(0, 0, 0, 0.3)
                        border.color: {
                            if (alarmIn.activeFocus) {
                                return ThemeManager.accentColor
                            }
                            return Qt.rgba(1, 1, 1, 0.1)
                        }
                        border.width: 1 
                    } 
                }

                BaseButton { 
                    width: 60
                    height: 40
                    cornerRadius: 8

                    onClicked: { 
                        if (root.chronoEngine) {
                            root.chronoEngine.registerAlarm(
                                alarmPicker.time, 
                                alarmIn.text
                            )
                            alarmIn.text = "" 
                        }
                    }

                    Rectangle { 
                        anchors.fill: parent
                        radius: 8
                        color: ThemeManager.accentColor 
                    }

                    Text { 
                        anchors.centerIn: parent
                        text: "Add"
                        color: ThemeManager.contentPrimaryColor 
                        font.weight: Font.Bold 
                    }
                }
            }
        }
    }

    ListView {
        id: alarmList
        Layout.fillWidth: true
        Layout.fillHeight: true
        model: {
            return root.chronoEngine ? root.chronoEngine.alarmStore : null
        }
        spacing: 8
        clip: true

        delegate: StyledCard { 
            width: ListView.view.width
            height: 60
            backgroundColor: {
                if (model.active) {
                    return Qt.rgba(1, 1, 1, 0.08)
                }
                return "transparent"
            }

            RowLayout { 
                anchors.fill: parent
                anchors.margins: 12

                ColumnLayout { 
                    spacing: 0
                    StyledLabel { 
                        text: String(model.time || "")
                        font.pixelSize: 18 
                    }
                    StyledLabel { 
                        text: String(model.label || "")
                        type: "caption"
                        opacity: 0.5 
                    } 
                }

                Item { 
                    Layout.fillWidth: true 
                }

                Switch { 
                    checked: !!model.active
                    onPositionChanged: {
                        if (down && root.chronoEngine) {
                            root.chronoEngine.updateAlarmState(
                                index, 
                                checked
                            )
                        }
                    }
                }

                BaseButton { 
                    width: 30
                    height: 30

                    onClicked: {
                        if (root.chronoEngine) {
                            root.chronoEngine.unregisterAlarm(index)
                        }
                    }

                    Text { 
                        anchors.centerIn: parent
                        text: "󰅖"
                        color: "red"
                        opacity: 0.5 
                    } 
                }
            }
        }
    }
}
