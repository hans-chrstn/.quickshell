import QtQuick

VisualLabInteractionFrame {
    id: root

    required property string title
    property string detail: ""

    implicitHeight: 58
    controlRadius: 13
    controlInset: 3
    selectionFillEnabled: false

    Text {
        anchors {
            left: parent.left
            right: switchTrack.left
            top: parent.top
            leftMargin: 14
            rightMargin: 12
            topMargin: root.detail.length > 0 ? 10 : 19
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
            left: parent.left
            right: switchTrack.left
            bottom: parent.bottom
            leftMargin: 14
            rightMargin: 12
            bottomMargin: 9
        }
        text: root.detail
        color: "#74747c"
        elide: Text.ElideRight
        font.family: "SF Pro Text"
        font.pixelSize: 9
    }

    Rectangle {
        id: switchTrack

        anchors {
            right: parent.right
            verticalCenter: parent.verticalCenter
            rightMargin: 14
        }
        width: 43
        height: 25
        radius: 12.5
        color: root.selected ? "#ffff9f0a" : "#20ffffff"
        border.width: root.selected ? 0 : 1
        border.color: "#20ffffff"

        Behavior on color {
            ColorAnimation {
                duration: 170
            }
        }

        Rectangle {
            x: root.selected ? parent.width - width - 3 : 3
            anchors.verticalCenter: parent.verticalCenter
            width: 19
            height: 19
            radius: 9.5
            color: "#f7f7f8"

            Behavior on x {
                NumberAnimation {
                    duration: 190
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: [0.2, 0, 0, 1, 1, 1]
                }
            }
        }
    }
}
