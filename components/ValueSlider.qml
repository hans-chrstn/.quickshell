import QtQuick
import QtQuick.Controls
import qs.core

Slider {
    id: root

    property color accentColor: Theme.selection
    property bool wheelStepEnabled: false
    signal editRequested(real value)
    signal wheelStepRequested(int steps)

    implicitHeight: 30
    hoverEnabled: true
    onMoved: root.editRequested(root.value)

    background: Rectangle {
        x: root.leftPadding
        y: root.topPadding + root.availableHeight / 2 - height / 2
        width: root.availableWidth
        height: 8
        radius: height / 2
        color: Theme.valueTrack

        Rectangle {
            width: root.visualPosition * parent.width
            height: parent.height
            radius: parent.radius
            color: root.accentColor

            Behavior on color {
                ColorAnimation {
                    duration: Design.motionStateDuration
                    easing.type: Design.motionStandardEasing
                }
            }
        }
    }

    handle: Rectangle {
        x: root.leftPadding + root.visualPosition * (root.availableWidth - width)
        y: root.topPadding + root.availableHeight / 2 - height / 2
        implicitWidth: root.pressed ? 22 : 20
        implicitHeight: implicitWidth
        radius: width / 2
        color: Theme.valueThumb
        border.width: root.activeFocus ? 2 : 1
        border.color: root.activeFocus ? Theme.focusRing : Theme.valueThumbBorder

        Behavior on implicitWidth {
            NumberAnimation {
                duration: 120
                easing.type: Design.motionStandardEasing
            }
        }

        Behavior on border.color {
            ColorAnimation {
                duration: Design.motionStateDuration
                easing.type: Design.motionStandardEasing
            }
        }
    }

    WheelHandler {
        enabled: root.enabled && root.wheelStepEnabled
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            const delta = event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x;
            if (delta !== 0)
                root.wheelStepRequested(delta > 0 ? 1 : -1);
            event.accepted = true;
        }
    }
}
