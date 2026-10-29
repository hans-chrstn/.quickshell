import QtQuick

Item {
    id: root

    property bool constrained: false

    Text {
        anchors {
            left: parent.left
            top: parent.top
            leftMargin: 14
            topMargin: 10
        }
        text: "TIMELINE"
        color: "#696970"
        font.family: "SF Pro Text"
        font.pixelSize: 9
        font.letterSpacing: 1.1
        font.weight: Font.DemiBold
    }

    Row {
        anchors {
            right: parent.right
            top: parent.top
            rightMargin: 12
            topMargin: 4
        }
        spacing: 1

        VisualLabGlyphButton {
            width: 30
            height: 30
            toggleable: false
            iconKind: "chevron"
        }

        VisualLabGlyphButton {
            width: 30
            height: 30
            toggleable: false
            iconKind: "more"
        }
    }

    Item {
        id: ruler

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            leftMargin: 76
            rightMargin: 12
            topMargin: root.constrained ? 32 : 36
        }
        height: root.constrained ? 10 : 13

        Repeater {
            model: 9

            Rectangle {
                required property int index

                x: index * ruler.width / 8
                width: 1
                height: index % 2 === 0 ? 8 : 5
                color: "#28ffffff"
            }
        }
    }

    Column {
        anchors {
            left: parent.left
            right: parent.right
            top: ruler.bottom
            leftMargin: 10
            rightMargin: 10
            topMargin: 2
        }
        spacing: 4

        Repeater {
            model: 2

            Item {
                required property int index

                width: parent.width
                height: root.constrained ? 23 : 30

                Text {
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                        leftMargin: 4
                    }
                    text: parent.index === 0 ? "V1" : "A1"
                    color: "#6f6f77"
                    font.family: "SF Pro Text"
                    font.pixelSize: 8
                    font.weight: Font.DemiBold
                }

                Rectangle {
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        bottom: parent.bottom
                        leftMargin: 66
                    }
                    radius: 8
                    color: "#08ffffff"

                    Rectangle {
                        x: parent.parent.index === 0 ? 5 : parent.width * 0.25
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.parent.index === 0 ? parent.width * 0.55 : parent.width * 0.42
                        height: root.constrained ? 17 : 22
                        radius: 7
                        color: parent.parent.index === 0 ? "#20ff9f0a" : "#16ffffff"
                        border.width: 1
                        border.color: parent.parent.index === 0 ? "#50ffaf32" : "#18ffffff"
                    }
                }
            }
        }
    }

    Rectangle {
        x: 76 + (parent.width - 88) * 0.38
        y: root.constrained ? 28 : 31
        width: 1
        height: parent.height - (root.constrained ? 34 : 38)
        color: "#ffffaf32"

        Rectangle {
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.top
            }
            width: 7
            height: 7
            radius: 3.5
            color: "#ffffaf32"
        }
    }
}
