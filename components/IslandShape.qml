import QtQuick
import QtQuick.Shapes
import qs.core

Shape {
    id: root

    property real wing: Design.wing
    property real bodyRadius: Design.bodyRadius
    property color fillColor: Design.island
    property color strokeColor: "transparent"
    property real strokeWidth: 0

    antialiasing: true
    layer.enabled: true
    layer.samples: 8
    layer.smooth: true

    ShapePath {
        id: path

        fillColor: root.fillColor
        strokeWidth: root.strokeWidth
        strokeColor: root.strokeColor

        readonly property real w: root.width
        readonly property real h: root.height
        readonly property real g: Math.max(0, Math.min(root.wing, h / 2, w / 6))
        readonly property real r: Math.max(0, Math.min(root.bodyRadius, h / 2,
                                                       w / 3 - g))

        startX: 0
        startY: 0

        PathArc {
            x: path.g
            y: path.g
            radiusX: path.g
            radiusY: path.g
            direction: PathArc.Clockwise
        }
        PathLine { x: path.g; y: path.h - path.r }
        PathArc {
            x: path.g + path.r
            y: path.h
            radiusX: path.r
            radiusY: path.r
            direction: PathArc.Counterclockwise
        }
        PathLine { x: path.w - path.g - path.r; y: path.h }
        PathArc {
            x: path.w - path.g
            y: path.h - path.r
            radiusX: path.r
            radiusY: path.r
            direction: PathArc.Counterclockwise
        }
        PathLine { x: path.w - path.g; y: path.g }
        PathArc {
            x: path.w
            y: 0
            radiusX: path.g
            radiusY: path.g
            direction: PathArc.Clockwise
        }
        PathLine { x: 0; y: 0 }
    }
}
