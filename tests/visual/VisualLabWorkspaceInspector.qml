import QtQuick

Item {
    id: root

    readonly property var properties: [
        {
            "label": "Scale",
            "value": "100%"
        },
        {
            "label": "Opacity",
            "value": "100%"
        },
        {
            "label": "Blend",
            "value": "Normal"
        },
        {
            "label": "Loop",
            "value": "Enabled"
        }
    ]

    Text {
        anchors {
            left: parent.left
            top: parent.top
            leftMargin: 14
            topMargin: 14
        }
        text: "INSPECTOR"
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
            topMargin: 14
        }
        text: "CLIP"
        color: "#ffffaf32"
        font.family: "SF Pro Text"
        font.pixelSize: 8
        font.weight: Font.DemiBold
    }

    Column {
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            leftMargin: 14
            rightMargin: 14
            topMargin: 40
        }

        Repeater {
            model: root.properties

            Item {
                required property var modelData

                width: parent.width
                height: 38

                Text {
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                    }
                    text: parent.modelData.label
                    color: "#888890"
                    font.family: "SF Pro Text"
                    font.pixelSize: 9
                }

                Text {
                    anchors {
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                    text: parent.modelData.value
                    color: "#dedee2"
                    font.family: "SF Pro Text"
                    font.pixelSize: 9
                    font.weight: Font.Medium
                }

                Rectangle {
                    anchors {
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                    }
                    height: 1
                    color: "#0dffffff"
                }
            }
        }
    }
}
