import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services

Item {
    id: root

    SystemClock {
        id: sysClock
        precision: SystemClock.Minutes
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: -4

        Text {
            id: timeText
            text: Qt.formatDateTime(sysClock.date, ThemeService.timeFormat)
            color: "white"
            font.weight: Font.DemiBold
            font.pixelSize: 52
            font.letterSpacing: -2
            renderType: Text.NativeRendering
            Layout.alignment: Qt.AlignHCenter
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 8
            Layout.topMargin: 2

            Rectangle {
                width: 4; height: 4; radius: 2
                color: ThemeService.accentColor
                opacity: 0.8
            }

            Text {
                id: dateText
                text: Qt.formatDateTime(sysClock.date, ThemeService.dateFormat).toUpperCase()
                color: "white"
                opacity: 0.4
                font.pixelSize: 9
                font.letterSpacing: 2
                font.weight: Font.Bold
                renderType: Text.NativeRendering
            }

            Rectangle {
                width: 4; height: 4; radius: 2
                color: ThemeService.accentColor
                opacity: 0.8
            }
        }
    }
}
