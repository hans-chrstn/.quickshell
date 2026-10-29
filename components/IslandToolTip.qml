import QtQuick
import QtQuick.Controls
import qs.core

ToolTip {
    id: root

    delay: 480
    timeout: 3200
    padding: 0
    leftPadding: 0
    rightPadding: 0

    contentItem: Text {
        leftPadding: 10
        rightPadding: 10
        topPadding: 7
        bottomPadding: 7
        text: root.text
        color: Theme.textPrimary
        font.family: Design.fontText
        font.pixelSize: Design.typeCaption
        font.weight: Font.Medium
    }

    background: Rectangle {
        radius: 9
        color: Theme.surfaceRaised
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
                easing.type: Design.motionStandardEasing
            }
        }
    }

    exit: Transition {
        NumberAnimation {
            property: "opacity"
            from: 1
            to: 0
            duration: Design.motionPressDuration
        }
    }
}
