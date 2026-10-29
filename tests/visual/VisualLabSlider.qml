import QtQuick

VisualLabInteractionFrame {
    id: root

    required property string title
    property string detail: ""
    property real value: 0.68
    property real stepSize: 0.05
    property bool dragging: false

    implicitHeight: 116
    activationEnabled: false
    externallyPressed: dragging
    controlRadius: 16
    controlInset: 3

    onDecreaseRequested: setValue(value - stepSize)
    onIncreaseRequested: setValue(value + stepSize)
    onMinimumRequested: setValue(0)
    onMaximumRequested: setValue(1)

    Text {
        anchors {
            left: parent.left
            top: parent.top
            leftMargin: 16
            topMargin: 15
        }
        text: root.title
        color: "#ededf0"
        font.family: "SF Pro Text"
        font.pixelSize: 12
        font.weight: Font.DemiBold
    }

    Text {
        anchors {
            right: parent.right
            top: parent.top
            rightMargin: 16
            topMargin: 15
        }
        text: Math.round(root.value * 100) + "%"
        color: root.activeFocus || root.dragging ? "#ffffaf32" : "#a1a1a8"
        font.family: "SF Pro Text"
        font.pixelSize: 11
        font.weight: Font.DemiBold
    }

    Text {
        anchors {
            left: parent.left
            top: parent.top
            leftMargin: 16
            topMargin: 35
        }
        text: root.detail
        color: "#74747c"
        font.family: "SF Pro Text"
        font.pixelSize: 9
    }

    Item {
        id: trackArea

        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            leftMargin: 16
            rightMargin: 16
            bottomMargin: 15
        }
        height: 30

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 8
            radius: 4
            color: "#18ffffff"
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width * root.value
            height: 8
            radius: 4
            color: "#ffff9f0a"
        }

        Rectangle {
            x: Math.max(0, Math.min(parent.width - width, parent.width * root.value - width / 2))
            anchors.verticalCenter: parent.verticalCenter
            width: root.dragging ? 22 : 20
            height: width
            radius: width / 2
            color: "#f7f7f8"
            border.width: 1
            border.color: "#24000000"

            Behavior on width {
                NumberAnimation {
                    duration: 120
                    easing.type: Easing.OutCubic
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            onPressed: mouse => {
                root.forceActiveFocus();
                root.dragging = true;
                root.setValue(mouse.x / width);
            }
            onPositionChanged: mouse => {
                if (pressed)
                    root.setValue(mouse.x / width);
            }
            onReleased: root.dragging = false
            onCanceled: root.dragging = false
        }
    }

    function setValue(nextValue) {
        value = Math.max(0, Math.min(1, nextValue));
    }
}
