import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.core

Item {
    id: root

    SystemClock {
        id: globalSystemClock
        precision: SystemClock.Minutes
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: -4

        Text {
            id: formattedTimeText
            text: Qt.formatDateTime(globalSystemClock.date, ThemeManager.timeFormat)
            color: ThemeManager.contentOnBackgroundColor
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
                width: 4
                height: 4
                radius: 2
                color: ThemeManager.accentColor
                opacity: 0.8
            }

            Text {
                id: formattedDateText
                text: Qt.formatDateTime(globalSystemClock.date, ThemeManager.dateFormat).toUpperCase()
                color: ThemeManager.contentOnBackgroundColor
                opacity: 0.4
                font.pixelSize: 9
                font.letterSpacing: 2
                font.weight: Font.Bold
                renderType: Text.NativeRendering
            }

            Rectangle {
                width: 4
                height: 4
                radius: 2
                color: ThemeManager.accentColor
                opacity: 0.8
            }
        }
    }
}
