import QtQuick

Item {
    id: root

    Text {
        anchors {
            left: parent.left
            top: parent.top
            leftMargin: 14
            topMargin: 12
        }
        text: "PREVIEW"
        color: "#696970"
        font.family: "SF Pro Text"
        font.pixelSize: 9
        font.letterSpacing: 1.1
        font.weight: Font.DemiBold
    }

    Text {
        anchors {
            right: parent.right
            top: parent.top
            rightMargin: 14
            topMargin: 12
        }
        text: "16:9 · FIT"
        color: "#62626a"
        font.family: "SF Pro Text"
        font.pixelSize: 8
        font.weight: Font.Medium
    }

    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            bottom: parent.bottom
            leftMargin: 14
            rightMargin: 14
            topMargin: 34
            bottomMargin: 13
        }
        radius: 15
        color: "#f0060608"
        border.width: 1
        border.color: "#16ffffff"
        clip: true

        Rectangle {
            x: parent.width * 0.58
            y: -parent.height * 0.2
            width: parent.height * 1.2
            height: width
            radius: width / 2
            color: "#20ff9f0a"
        }

        Rectangle {
            x: -parent.height * 0.3
            y: parent.height * 0.44
            width: parent.height
            height: width
            radius: width / 2
            color: "#10ffffff"
        }

        Text {
            anchors.centerIn: parent
            text: "AURORA"
            color: "#e8e8eb"
            font.family: "SF Pro Display"
            font.pixelSize: 17
            font.letterSpacing: 3
            font.weight: Font.DemiBold
        }
    }
}
