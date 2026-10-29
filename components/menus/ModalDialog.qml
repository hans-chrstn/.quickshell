import QtQuick
import QtQuick.Controls
import qs.core

Dialog {
    id: root

    property real preferredWidth: 360

    parent: Overlay.overlay
    width: Math.min(preferredWidth, Math.max(0, (parent?.width ?? preferredWidth + 16) - 16))
    x: parent ? (parent.width - width) / 2 : 0
    y: parent ? Math.max(8, (parent.height - implicitHeight) / 2) : 0
    padding: 16
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    header: null
    footer: null
    transformOrigin: Item.Center

    background: Rectangle {
        radius: 18
        color: Theme.alpha(Theme.surfaceRaised, 1)
        border.width: 1
        border.color: Theme.separatorStrong
    }

    enter: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: Design.motionStateDuration
            }
            NumberAnimation {
                property: "scale"
                from: 0.97
                to: 1
                duration: Design.motionControlDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Design.motionControlCurve
            }
        }
    }

    exit: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "opacity"
                from: 1
                to: 0
                duration: Design.motionPressDuration
            }
            NumberAnimation {
                property: "scale"
                from: 1
                to: 0.985
                duration: Design.motionPressDuration
                easing.type: Design.motionStandardEasing
            }
        }
    }
}
