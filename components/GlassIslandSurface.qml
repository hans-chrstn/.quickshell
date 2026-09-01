import QtQuick
import QtQuick.Effects
import qs.core
import qs.components

Item {
    id: root

    property bool expanded: false
    property real expansionProgress: 0

    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: root.expanded
        shadowColor: "#a8000000"
        shadowBlur: 0.55
        shadowVerticalOffset: 2
        saturation: 0.92
    }

    IslandShape {
        anchors.fill: parent
        fillColor: Qt.rgba(
            Design.island.r + (Design.islandExpanded.r - Design.island.r) * root.expansionProgress,
            Design.island.g + (Design.islandExpanded.g - Design.island.g) * root.expansionProgress,
            Design.island.b + (Design.islandExpanded.b - Design.island.b) * root.expansionProgress,
            Design.island.a + (Design.islandExpanded.a - Design.island.a) * root.expansionProgress)
    }

    IslandShape {
        anchors.fill: parent
        fillColor: "transparent"
        strokeColor: Design.glassStroke
        strokeWidth: 1
        opacity: 0.72 + 0.28 * root.expansionProgress
    }

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 1
        width: Math.max(0, parent.width - (Design.wing + Design.bodyRadius) * 2)
        height: 1
        color: Design.glassShade
        opacity: 0.45 + 0.35 * root.expansionProgress
    }
}
