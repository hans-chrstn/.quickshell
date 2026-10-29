import QtQuick

Item {
    id: root

    property int currentIndex: 0
    readonly property var assets: [
        {
            "label": "Aurora",
            "detail": "Video · 24 fps"
        },
        {
            "label": "Still frame",
            "detail": "Image · 4K"
        },
        {
            "label": "Evening glow",
            "detail": "Scene · 12 s"
        }
    ]

    Text {
        anchors {
            left: parent.left
            top: parent.top
            leftMargin: 14
            topMargin: 14
        }
        text: "LIBRARY"
        color: "#696970"
        font.family: "SF Pro Text"
        font.pixelSize: 9
        font.letterSpacing: 1.1
        font.weight: Font.DemiBold
    }

    Column {
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            leftMargin: 7
            rightMargin: 7
            topMargin: 36
        }
        spacing: 2

        Repeater {
            model: root.assets

            VisualLabInteractionFrame {
                id: assetRow

                required property int index
                required property var modelData

                width: parent.width
                height: 48
                selected: root.currentIndex === index
                controlRadius: 11
                controlInset: 2
                onActivated: root.currentIndex = index

                Rectangle {
                    id: assetMark

                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                        leftMargin: 10
                    }
                    width: 28
                    height: 28
                    radius: 9
                    color: assetRow.selected ? "#20ff9f0a" : "#0bffffff"

                    VisualLabControlGlyph {
                        anchors.centerIn: parent
                        width: 13
                        height: 13
                        iconKind: assetRow.index === 0 ? "spark" : assetRow.index === 1 ? "diamond" : "check"
                        glyphColor: assetRow.selected ? "#ffffaf32" : "#92929a"
                    }
                }

                Text {
                    anchors {
                        left: assetMark.right
                        right: parent.right
                        top: parent.top
                        leftMargin: 9
                        rightMargin: 8
                        topMargin: 9
                    }
                    text: assetRow.modelData.label
                    color: "#e8e8eb"
                    elide: Text.ElideRight
                    font.family: "SF Pro Text"
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                }

                Text {
                    anchors {
                        left: assetMark.right
                        right: parent.right
                        bottom: parent.bottom
                        leftMargin: 9
                        rightMargin: 8
                        bottomMargin: 8
                    }
                    text: assetRow.modelData.detail
                    color: "#6f6f77"
                    elide: Text.ElideRight
                    font.family: "SF Pro Text"
                    font.pixelSize: 8
                }
            }
        }
    }

    Text {
        anchors {
            left: parent.left
            bottom: parent.bottom
            leftMargin: 14
            bottomMargin: 12
        }
        text: "3 assets"
        color: "#63636b"
        font.family: "SF Pro Text"
        font.pixelSize: 9
    }
}
