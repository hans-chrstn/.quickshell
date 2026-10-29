import QtQuick
import QtQuick.Controls

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
        color: "#e8e8eb"
        font.family: "SF Pro Text"
        font.pixelSize: 10
        font.weight: Font.Medium
    }

    background: Rectangle {
        radius: 9
        color: "#f21b1b1f"
        border.width: 1
        border.color: "#24ffffff"
    }

    enter: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: 120
            }
            NumberAnimation {
                property: "scale"
                from: 0.97
                to: 1
                duration: 150
                easing.type: Easing.OutCubic
            }
        }
    }

    exit: Transition {
        NumberAnimation {
            property: "opacity"
            from: 1
            to: 0
            duration: 90
        }
    }
}
