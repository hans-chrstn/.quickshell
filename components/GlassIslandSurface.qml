import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import qs.core
import qs.components

Item {
    id: root

    property bool backdropAvailable: true
    property bool expanded: false
    property real expansionProgress: 0
    readonly property real surfaceRadius: Design.bodyRadius + (Design.expandedBodyRadius - Design.bodyRadius) * expansionProgress
    readonly property color envelopeColor: backdropAvailable ? Theme.mix(Theme.envelopeCompact, Theme.envelopeExpanded, expansionProgress) : Theme.envelopeOpaque
    readonly property bool shadowActive: expansionProgress > 0.001
    readonly property real wingCurveSize: Math.max(0, Math.min(Design.wing, root.height / 2, root.width / 6))

    layer.enabled: shadowActive
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: Theme.shadow
        shadowBlur: 0.48
        shadowVerticalOffset: 3
        shadowOpacity: 0.44 * root.expansionProgress
    }

    IslandShape {
        anchors.fill: parent
        bodyRadius: root.surfaceRadius
        fillColor: root.envelopeColor
    }

    IslandShape {
        anchors.fill: parent
        bodyRadius: root.surfaceRadius
        fillColor: Theme.surfaceSheen
        opacity: root.backdropAvailable ? 0.28 + 0.16 * root.expansionProgress : 0.18
    }

    IslandShape {
        anchors.fill: parent
        bodyRadius: root.surfaceRadius
        fillColor: "transparent"
        strokeColor: Theme.surfaceEdgeLight
        strokeWidth: 1
        opacity: 0.44 + 0.18 * root.expansionProgress
    }

    Shape {
        id: wingEdge

        anchors.fill: parent
        antialiasing: true

        ShapePath {
            fillColor: "transparent"
            strokeColor: Theme.surfaceEdgeLight
            strokeWidth: 1
            startX: 0
            startY: 0

            PathArc {
                x: root.wingCurveSize
                y: root.wingCurveSize
                radiusX: root.wingCurveSize
                radiusY: root.wingCurveSize
                direction: PathArc.Clockwise
            }
        }

        ShapePath {
            fillColor: "transparent"
            strokeColor: Theme.surfaceEdgeLight
            strokeWidth: 1
            startX: root.width - root.wingCurveSize
            startY: root.wingCurveSize

            PathArc {
                x: root.width
                y: 0
                radiusX: root.wingCurveSize
                radiusY: root.wingCurveSize
                direction: PathArc.Clockwise
            }
        }

        opacity: 0.4 + 0.2 * root.expansionProgress
    }

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 1
        width: Math.max(0, parent.width - (Design.wing + root.surfaceRadius) * 2)
        height: 1
        color: Theme.surfaceDepthEdge
        opacity: 0.4 + 0.24 * root.expansionProgress
    }
}
