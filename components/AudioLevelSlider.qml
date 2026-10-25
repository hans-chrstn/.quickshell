import QtQuick
import QtQuick.Controls
import qs.core

Slider {
    id: root

    property color accentColor: Theme.textPrimary
    signal levelEdited(real value)
    signal stepRequested(int steps)

    from: 0
    to: 1
    stepSize: 0.01
    Accessible.name: "Sound level"
    onMoved: levelEdited(value)

    background: Rectangle {
        x: root.leftPadding
        y: root.topPadding + root.availableHeight / 2 - height / 2
        width: root.availableWidth
        height: 16
        radius: height / 2
        color: Theme.fillElevated

        Rectangle {
            width: root.visualPosition * parent.width
            height: parent.height
            radius: parent.radius
            color: root.accentColor

            Behavior on color {
                ColorAnimation {
                    duration: 120
                }
            }
        }
    }

    handle: Rectangle {
        x: root.leftPadding + root.visualPosition * (root.availableWidth - width)
        y: root.topPadding + root.availableHeight / 2 - height / 2
        implicitWidth: 22
        implicitHeight: 22
        radius: width / 2
        color: Theme.textPrimary
        border.width: 1
        border.color: Theme.controlShadow
        scale: root.pressed ? 1.14 : 1

        Behavior on scale {
            NumberAnimation {
                duration: 90
                easing.type: Easing.OutCubic
            }
        }
    }

    WheelHandler {
        enabled: root.enabled
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            const delta = event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x;
            if (delta !== 0)
                root.stepRequested(delta > 0 ? 1 : -1);
            event.accepted = true;
        }
    }
}
