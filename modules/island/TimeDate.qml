import QtQuick
import QtQuick.Layouts

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
        spacing: 0

        Text {
            id: timeText
            text: Qt.formatDateTime(new Date(), "hh:mm")
            color: "white"
            font.weight: Font.DemiBold
            font.pixelSize: 48
            font.letterSpacing: -1
            Layout.alignment: Qt.AlignHCenter
        }

        Text {
            id: dateText
            text: Qt.formatDateTime(new Date(), "dddd, MMMM d").toUpperCase()
            color: "white"
            opacity: 0.5
            font.pixelSize: 11
            font.letterSpacing: 1.5
            font.weight: Font.Medium
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: -4
        }
    }
}
