import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import qs.core
import qs.ui.shared

Item {
    id: root

    property date selectedDate: new Date()
    property date viewDate: new Date(selectedDate)
    
    signal dateSelected(date date)
    signal closed()

    implicitWidth: 300
    implicitHeight: 340

    function prevMonth() {
        let d = new Date(root.viewDate)
        d.setMonth(
            d.getMonth() - 1
        )
        root.viewDate = d
    }

    function nextMonth() {
        let d = new Date(root.viewDate)
        d.setMonth(
            d.getMonth() + 1
        )
        root.viewDate = d
    }

    StyledCard {
        anchors.fill: parent
        backgroundColor: ThemeManager.surfaceStrongColor
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 15
            spacing: 15

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                StyledLabel {
                    text: {
                        return root.viewDate.toLocaleDateString(Qt.locale(), "MMMM yyyy")
                    }
                    type: "title"
                    font.pixelSize: 16
                    Layout.fillWidth: true
                }

                BaseButton {
                    width: 32
                    height: 32
                    cornerRadius: 8
                    onClicked: {
                        root.prevMonth()
                        SoundManager.playClick()
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "󰁍"
                        color: ThemeManager.contentOnBackgroundColor
                        font.pixelSize: 18
                        opacity: {
                            return parent.isHovered ? 1.0 : 0.6
                        }
                    }
                }

                BaseButton {
                    width: 32
                    height: 32
                    cornerRadius: 8
                    onClicked: {
                        root.nextMonth()
                        SoundManager.playClick()
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "󰁔"
                        color: ThemeManager.contentOnBackgroundColor
                        font.pixelSize: 18
                        opacity: {
                            return parent.isHovered ? 1.0 : 0.6
                        }
                    }
                }
            }

            Grid {
                id: calendarGrid
                Layout.fillWidth: true
                columns: 7
                spacing: 4

                Repeater {
                    model: [
                        "Mo", 
                        "Tu", 
                        "We", 
                        "Th", 
                        "Fr", 
                        "Sa", 
                        "Su"
                    ]
                    
                    delegate: StyledLabel {
                        width: {
                            return (calendarGrid.width - (4 * 6)) / 7
                        }
                        text: modelData
                        type: "caption"
                        horizontalAlignment: Text.AlignHCenter
                        opacity: 0.5
                    }
                }

                Repeater {
                    model: {
                        let d = new Date(root.viewDate)
                        d.setDate(1)
                        
                        let startDay = d.getDay()
                        if (startDay === 0) {
                            startDay = 7
                        }
                        
                        let daysInPrev = new Date(
                            d.getFullYear(), 
                            d.getMonth(), 
                            0
                        ).getDate()
                        
                        let daysInCurr = new Date(
                            d.getFullYear(), 
                            d.getMonth() + 1, 
                            0
                        ).getDate()
                        
                        let res = []
                        for (let i = startDay - 1; i > 0; i--) {
                            res.push({ 
                                day: daysInPrev - i + 1, 
                                current: false 
                            })
                        }
                        
                        for (let i = 1; i <= daysInCurr; i++) {
                            res.push({ 
                                day: i, 
                                current: true 
                            })
                        }
                        
                        return res
                    }

                    delegate: BaseButton {
                        width: {
                            return (calendarGrid.width - (4 * 6)) / 7
                        }
                        height: width
                        cornerRadius: 8
                        
                        readonly property bool isSelected: {
                            if (!modelData.current) {
                                return false
                            }
                            let s = root.selectedDate
                            let v = root.viewDate
                            return s.getDate() === modelData.day 
                                && s.getMonth() === v.getMonth() 
                                && s.getFullYear() === v.getFullYear()
                        }

                        readonly property bool isToday: {
                            if (!modelData.current) {
                                return false
                            }
                            let t = new Date()
                            let v = root.viewDate
                            return t.getDate() === modelData.day 
                                && t.getMonth() === v.getMonth() 
                                && t.getFullYear() === v.getFullYear()
                        }

                        onClicked: {
                            if (modelData.current) {
                                let d = new Date(root.viewDate)
                                d.setDate(modelData.day)
                                root.dateSelected(d)
                                SoundManager.playClick()
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: 8
                            color: {
                                if (parent.isSelected) {
                                    return ThemeManager.accentColor
                                }
                                if (parent.isToday) {
                                    return ThemeManager.surfaceSubtleColor
                                }
                                return "transparent"
                            }
                            border.color: ThemeManager.outlineVariantColor
                            border.width: {
                                return (parent.isToday && !parent.isSelected) ? 1 : 0
                            }
                            opacity: {
                                return modelData.current ? 1.0 : 0.2
                            }
                        }

                        StyledLabel {
                            anchors.centerIn: parent
                            text: modelData.day
                            type: "body"
                            font.pixelSize: 12
                            font.weight: {
                                return parent.isToday ? Font.Bold : Font.Normal
                            }
                            color: {
                                if (parent.isSelected) {
                                    return ThemeManager.contentPrimaryColor
                                }
                                return ThemeManager.contentOnBackgroundColor
                            }
                        }
                    }
                }
            }

            Item {
                Layout.fillHeight: true
            }

            BaseButton {
                Layout.fillWidth: true
                height: 36
                cornerRadius: 8
                onClicked: {
                    root.closed()
                    SoundManager.playClick()
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 8
                    color: ThemeManager.surfaceSubtleColor
                }

                StyledLabel {
                    anchors.centerIn: parent
                    text: "Close"
                    type: "label"
                }
            }
        }
    }
}
