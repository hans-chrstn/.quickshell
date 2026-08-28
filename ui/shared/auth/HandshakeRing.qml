import QtQuick
import QtQuick.Shapes
import qs.core

Item {
    id: root

    implicitWidth: 160

    implicitHeight: 160

    property bool active: false

    Rectangle {
        anchors.centerIn: parent

        width: 140

        height: 140

        radius: 70

        color: "transparent"

        border {
            color: ThemeManager.accentColor
            width: 1
        }

        opacity: 0.2
    }

    Item {
        id: ringContainer

        anchors.fill: parent

        rotation: 0

        NumberAnimation on rotation {
            from: 0
            to: 360
            duration: {
                if (root.active) {
                    return 2000
                }
                return 8000
            }
            loops: Animation.Infinite
            running: true
        }

        Repeater {
            model: 4

            Rectangle {
                readonly property real angle: (index * 90) * (Math.PI / 180)

                x: (root.width / 2) + Math.cos(angle) * 70 - 2

                y: (root.height / 2) + Math.sin(angle) * 70 - 2

                width: 4

                height: 4

                color: ThemeManager.accentColor

                opacity: {
                    if (root.active) {
                        return 0.8
                    }
                    return 0.3
                }
            }
        }

        Canvas {
            anchors.fill: parent

            onPaint: {
                let ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                ctx.strokeStyle = ThemeManager.accentColor
                ctx.lineWidth = 2
                
                let cx = width / 2
                let cy = height / 2
                
                ctx.beginPath()
                ctx.arc(cx, cy, 70, 0, Math.PI / 4)
                ctx.stroke()
                
                ctx.beginPath()
                ctx.arc(cx, cy, 70, Math.PI, Math.PI + (Math.PI / 4))
                ctx.stroke()
            }
        }
    }

    Shape {
        anchors.centerIn: parent

        width: 150

        height: 150

        opacity: {
            if (root.active) {
                return 0.4
            }
            return 0.1
        }

        layer.enabled: true
        layer.samples: 4

        RotationAnimation on rotation {
            from: 360
            to: 0
            duration: 12000
            loops: Animation.Infinite
            running: true
        }

        ShapePath {
            fillColor: "transparent"
            strokeColor: ThemeManager.accentColor
            strokeWidth: 1
            strokeStyle: ShapePath.DashLine
            dashPattern: [2, 10]

            PathAngleArc {
                centerX: 75
                centerY: 75
                radiusX: 75
                radiusY: 75
                startAngle: 0
                sweepAngle: 360
            }
        }
    }
}
