import QtQuick
import QtQuick.Effects
import qs.core
import qs.components

Item {
    id: root

    property bool expanded: false
    property real expansionProgress: 0
    readonly property real surfaceRadius: Design.bodyRadius + (Design.expandedBodyRadius - Design.bodyRadius) * expansionProgress

    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: root.expanded
        shadowColor: Theme.shadow
        shadowBlur: 0.48
        shadowVerticalOffset: 3
        saturation: 0
    }

    IslandShape {
        anchors.fill: parent
        bodyRadius: root.surfaceRadius
        fillColor: Theme.mix(Theme.islandCollapsed, Theme.islandExpanded, root.expansionProgress)
    }

    IslandShape {
        anchors.fill: parent
        bodyRadius: root.surfaceRadius
        fillColor: "transparent"
        strokeColor: Theme.glassStroke
        strokeWidth: 1
        opacity: 0.78 + 0.22 * root.expansionProgress
    }

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 1
        width: Math.max(0, parent.width - (Design.wing + root.surfaceRadius) * 2)
        height: 1
        color: Theme.glassShade
        opacity: 0.36 + 0.28 * root.expansionProgress
    }
}
