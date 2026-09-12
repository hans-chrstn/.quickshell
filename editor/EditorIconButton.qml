import QtQuick
import qs.core

Rectangle {
    id: root

    property string accessibleName: ""
    signal clicked()

    implicitWidth: 32
    implicitHeight: 32
    radius: 10
    color: press.pressed ? Qt.rgba(1, 1, 1, 0.13)
        : hover.hovered ? Qt.rgba(1, 1, 1, 0.08) : "transparent"

    Behavior on color { ColorAnimation { duration: 100 } }

    Canvas {
        anchors.centerIn: parent
        width: 12
        height: 12
        onPaint: {
            const context = getContext("2d")
            context.reset()
            context.strokeStyle = Design.textMuted
            context.lineWidth = 1.5
            context.lineCap = "round"
            context.beginPath()
            context.moveTo(2, 2)
            context.lineTo(10, 10)
            context.moveTo(10, 2)
            context.lineTo(2, 10)
            context.stroke()
        }
    }

    HoverHandler { id: hover }
    TapHandler { id: press; onTapped: root.clicked() }
}
