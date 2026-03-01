import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.core
import qs.ui.shared

Item {
    id: root

    SystemClock {
        id: globalSystemClock
        precision: SystemClock.Minutes
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: -4

        StyledLabel {
            id: formattedTimeText
            type: "clock"
            text: Qt.formatDateTime(globalSystemClock.date, ThemeManager.timeFormat)
            Layout.alignment: Qt.AlignHCenter
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 8
            Layout.topMargin: 2

            Rectangle {
                width: 4; height: 4; radius: 2
                color: ThemeManager.accentColor
                opacity: 0.8
                
                SequentialAnimation on scale {
                    loops: Animation.Infinite
                    NumberAnimation { to: 1.2; duration: 1500; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0; duration: 1500; easing.type: Easing.InOutSine }
                }
            }

            StyledLabel {
                id: formattedDateText
                type: "caption"
                text: Qt.formatDateTime(globalSystemClock.date, ThemeManager.dateFormat).toUpperCase()
                opacity: 0.4
                font.weight: Font.Bold
                font.pixelSize: 9
                font.letterSpacing: 2
            }

            Rectangle {
                width: 4; height: 4; radius: 2
                color: ThemeManager.accentColor
                opacity: 0.8
                
                SequentialAnimation on scale {
                    loops: Animation.Infinite
                    NumberAnimation { to: 1.2; duration: 1500; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0; duration: 1500; easing.type: Easing.InOutSine }
                }
            }
        }
    }
}
