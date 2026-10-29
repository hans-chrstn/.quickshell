import QtQuick

VisualLabInteractionFrame {
    id: root

    required property string title
    property string detail: ""

    Rectangle {
        id: statusMark

        anchors {
            left: parent.left
            verticalCenter: parent.verticalCenter
            leftMargin: 14
        }
        width: 7
        height: 7
        radius: 3.5
        color: root.semanticRole !== "neutral" ? root.semanticColor : root.selected ? "#ffffa21a" : "#73737b"
        opacity: root.selected || root.semanticRole !== "neutral" ? 1 : 0.22
        scale: root.selected ? 1 : 0.72

        Behavior on opacity {
            NumberAnimation {
                duration: 140
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }
    }

    Text {
        anchors {
            left: statusMark.right
            right: parent.right
            top: parent.top
            leftMargin: 10
            rightMargin: 12
            topMargin: root.detail.length > 0 ? 12 : 21
        }
        text: root.title
        color: "#ededf0"
        elide: Text.ElideRight
        font.family: "SF Pro Text"
        font.pixelSize: 12
        font.weight: Font.DemiBold
    }

    Text {
        anchors {
            left: statusMark.right
            right: parent.right
            bottom: parent.bottom
            leftMargin: 10
            rightMargin: 12
            bottomMargin: 11
        }
        text: root.detail
        color: root.semanticRole === "neutral" ? "#787880" : root.semanticColor
        elide: Text.ElideRight
        font.family: "SF Pro Text"
        font.pixelSize: 9
    }
}
