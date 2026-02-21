import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.config

Item {
    id: root

    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: {
            let now = new Date();
            let newTime = Qt.formatDateTime(now, FrameConfig.timeFormat);
            let newDate = Qt.formatDateTime(now, FrameConfig.dateFormat).toUpperCase();
            if (timeText.text !== newTime) timeText.text = newTime;
            if (dateText.text !== newDate) dateText.text = newDate;
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: -4

        Text {
            id: timeText
            text: Qt.formatDateTime(new Date(), FrameConfig.timeFormat)
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
                color: FrameConfig.accentColor
                opacity: 0.8
            }

            Text {
                id: dateText
                text: Qt.formatDateTime(new Date(), FrameConfig.dateFormat).toUpperCase()
                color: "white"
                opacity: 0.4
                font.pixelSize: 9
                font.letterSpacing: 2
                font.weight: Font.Bold
                renderType: Text.NativeRendering
            }

            Rectangle {
                width: 4; height: 4; radius: 2
                color: FrameConfig.accentColor
                opacity: 0.8
            }
        }
    }
}
