import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.config

Item {
    id: root

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            timeText.text = Qt.formatDateTime(new Date(), "hh:mm")
            dateText.text = Qt.formatDateTime(new Date(), "dddd, MMMM d")
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: -4

        Text {
            id: timeText
            text: Qt.formatDateTime(new Date(), "hh:mm")
            color: "white"
            font.weight: Font.DemiBold
            font.pixelSize: 52
            font.letterSpacing: -2
            Layout.alignment: Qt.AlignHCenter
            
            layer.enabled: true
            layer.effect: MultiEffect {
                blurEnabled: true
                blur: 0.1
                brightness: 0.1
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 8
            Layout.topMargin: 2

            Rectangle {
                width: 4; height: 4; radius: 2
                color: FrameConfig.accentColor
                opacity: 0.8
            }

            Text {
                id: dateText
                text: Qt.formatDateTime(new Date(), "dddd, MMMM d").toUpperCase()
                color: "white"
                opacity: 0.4
                font.pixelSize: 9
                font.letterSpacing: 2
                font.weight: Font.Bold
            }

            Rectangle {
                width: 4; height: 4; radius: 2
                color: FrameConfig.accentColor
                opacity: 0.8
            }
        }
    }
}