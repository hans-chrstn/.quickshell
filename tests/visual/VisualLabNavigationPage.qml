import QtQuick

Item {
    id: root

    required property string title
    required property string detail
    required property string status
    required property string iconKind

    Rectangle {
        anchors.fill: parent
        radius: 18
        color: "#05ffffff"
        border.width: 1
        border.color: "#10ffffff"
    }

    Rectangle {
        id: iconWell

        anchors {
            left: parent.left
            verticalCenter: parent.verticalCenter
            leftMargin: 16
        }
        width: 42
        height: 42
        radius: 14
        color: "#18ffffff"

        VisualLabControlGlyph {
            anchors.centerIn: parent
            width: 19
            height: 19
            iconKind: root.iconKind
            glyphColor: "#ffffaf32"
        }
    }

    Text {
        anchors {
            left: iconWell.right
            right: statusText.left
            top: parent.top
            leftMargin: 14
            rightMargin: 18
            topMargin: 22
        }
        text: root.title
        color: "#efeff1"
        elide: Text.ElideRight
        font.family: "SF Pro Text"
        font.pixelSize: 13
        font.weight: Font.DemiBold
    }

    Text {
        anchors {
            left: iconWell.right
            right: statusText.left
            bottom: parent.bottom
            leftMargin: 14
            rightMargin: 18
            bottomMargin: 21
        }
        text: root.detail
        color: "#77777f"
        elide: Text.ElideRight
        font.family: "SF Pro Text"
        font.pixelSize: 10
    }

    Text {
        id: statusText

        anchors {
            right: parent.right
            verticalCenter: parent.verticalCenter
            rightMargin: 18
        }
        text: root.status.toUpperCase()
        color: "#ffffaf32"
        font.family: "SF Pro Text"
        font.pixelSize: 9
        font.letterSpacing: 1
        font.weight: Font.DemiBold
    }
}
