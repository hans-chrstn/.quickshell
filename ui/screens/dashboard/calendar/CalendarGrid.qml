import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.core
import qs.ui.shared

ColumnLayout {
    id: root

    property date viewDate: new Date()
    property date selectedDate: CalendarManager.selectedDate
    
    spacing: 15

    function prevMonth() {
        let d = new Date(root.viewDate)
        d.setMonth(d.getMonth() - 1)
        root.viewDate = d
        refreshGoogleMonth()
    }

    function nextMonth() {
        let d = new Date(root.viewDate)
        d.setMonth(d.getMonth() + 1)
        root.viewDate = d
        refreshGoogleMonth()
    }

    function refreshGoogleMonth() {
        if (ThemeManager.googleCalendarEnabled) {
            let start = new Date(root.viewDate.getFullYear(), root.viewDate.getMonth(), 1)
            let end = new Date(root.viewDate.getFullYear(), root.viewDate.getMonth() + 1, 0)
            GoogleCalendarManager.fetchEvents(start, end)
        }
    }

    Component.onCompleted: refreshGoogleMonth()

    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        StyledLabel {
            text: Qt.formatDateTime(root.viewDate, "MMMM yyyy")
            type: "title"
            font.pixelSize: 18
            Layout.fillWidth: true
        }

        BaseButton {
            width: 32
            height: 32
            cornerRadius: 8
            tooltip: "Previous Month"
            onClicked: root.prevMonth()

            Text {
                anchors.centerIn: parent
                text: "󰁍"
                color: ThemeManager.contentOnBackgroundColor
                font.pixelSize: 18
                opacity: parent.isHovered ? 1.0 : 0.6
            }
        }

        BaseButton {
            width: 32
            height: 32
            cornerRadius: 8
            tooltip: "Next Month"
            onClicked: root.nextMonth()

            Text {
                anchors.centerIn: parent
                text: "󰁔"
                color: ThemeManager.contentOnBackgroundColor
                font.pixelSize: 18
                opacity: parent.isHovered ? 1.0 : 0.6
            }
        }
    }

    Grid {
        Layout.fillWidth: true
        columns: 7
        spacing: 4

        Repeater {
            model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
            delegate: StyledLabel {
                width: (parent.width - 24) / 7
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
                if (startDay === 0) startDay = 7
                let daysInPrev = new Date(d.getFullYear(), d.getMonth(), 0).getDate()
                let daysInCurr = new Date(d.getFullYear(), d.getMonth() + 1, 0).getDate()
                
                let res = []
                for (let i = startDay - 1; i > 0; i--) {
                    res.push({ day: daysInPrev - i + 1, current: false })
                }
                for (let i = 1; i <= daysInCurr; i++) {
                    res.push({ day: i, current: true })
                }
                return res
            }

            delegate: BaseButton {
                width: (parent.width - 24) / 7
                height: width
                cornerRadius: 8
                
                readonly property bool isSelected: {
                    if (!modelData.current) return false
                    let d = root.selectedDate
                    let v = root.viewDate
                    return d.getDate() === modelData.day 
                        && d.getMonth() === v.getMonth() 
                        && d.getFullYear() === v.getFullYear()
                }

                readonly property bool isToday: {
                    if (!modelData.current) return false
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
                        CalendarManager.selectedDate = d
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 8
                    color: parent.isSelected 
                        ? ThemeManager.accentColor 
                        : (parent.isToday ? ThemeManager.surfaceStrongColor : "transparent")
                    border.color: ThemeManager.outlineVariantColor
                    border.width: parent.isToday && !parent.isSelected ? 1 : 0
                    opacity: modelData.current ? 1.0 : 0.3
                    
                    scale: parent.isSelected ? 1.05 : 1.0
                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

                    layer.enabled: parent.isSelected
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: ThemeManager.accentColor
                        shadowOpacity: 0.4
                        shadowBlur: 0.5
                        shadowVerticalOffset: 1
                        blurEnabled: true
                    }
                }

                StyledLabel {
                    anchors.centerIn: parent
                    text: modelData.day
                    type: "body"
                    font.weight: parent.isToday ? Font.Bold : Font.Normal
                    color: parent.isSelected 
                        ? ThemeManager.contentPrimaryColor 
                        : ThemeManager.contentOnBackgroundColor
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 4
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 4
                    height: 4
                    radius: 2
                    color: parent.isSelected 
                        ? ThemeManager.contentPrimaryColor 
                        : ThemeManager.accentColor
                    visible: {
                        if (!modelData.current) return false
                        let d = new Date(root.viewDate)
                        d.setDate(modelData.day)
                        return CalendarManager.hasEventsOnDate(d)
                    }
                }
            }
        }
    }
}
