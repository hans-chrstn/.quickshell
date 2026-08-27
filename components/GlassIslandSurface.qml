import QtQuick
import QtQuick.Effects
import qs.core
import qs.components

Item {
    id: root

    property bool expanded: false

    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: root.expanded
        shadowColor: "#a8000000"
        shadowBlur: 0.55
        shadowVerticalOffset: 8
        saturation: 0.92
    }

    IslandShape {
        anchors.fill: parent
        fillColor: root.expanded ? Design.islandExpanded : Design.island

        Behavior on fillColor { ColorAnimation { duration: 220 } }
    }

    IslandShape {
        anchors.fill: parent
        fillColor: "transparent"
        strokeColor: Design.glassStroke
        strokeWidth: 1
        opacity: root.expanded ? 1 : 0.72

        Behavior on opacity { NumberAnimation { duration: 220 } }
    }

    Rectangle {
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.max(0, parent.width - (Design.wing + 10) * 2)
        height: 1
        color: Design.glassHighlight
    }

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 1
        width: Math.max(0, parent.width - (Design.wing + Design.bodyRadius) * 2)
        height: 1
        color: Design.glassShade
        opacity: root.expanded ? 0.8 : 0.45
    }
}
