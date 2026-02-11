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
        spacing: 4

        Text {
            id: timeText
            text: Qt.formatDateTime(new Date(), "hh:mm")
            color: "white"
            font.bold: true
            font.pixelSize: 40
            Layout.alignment: Qt.AlignHCenter
        }

        Text {
            id: dateText
            text: Qt.formatDateTime(new Date(), "dddd, MMMM d")
            color: "#aaa"
            font.pixelSize: 12
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
