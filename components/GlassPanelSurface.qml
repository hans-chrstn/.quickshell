import QtQuick
import qs.core

Item {
    id: root

    property real cornerRadius: Design.radiusPanel
    property bool backdropAvailable: true
    property real emphasis: 0
    readonly property real progress: Math.max(0, Math.min(1, emphasis))
    readonly property color materialColor: backdropAvailable ? Theme.mix(Theme.glassPanelCompact, Theme.glassPanelExpanded, progress) : Theme.envelopeOpaque

    Rectangle {
        anchors.fill: parent
        radius: root.cornerRadius
        color: root.materialColor
        border.width: 1
        border.color: Theme.glassPanelStroke
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: Math.max(0, root.cornerRadius - 1)
        color: Theme.surfaceSheen
        opacity: root.backdropAvailable ? 0.28 + 0.14 * root.progress : 0.12
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: root.cornerRadius
        anchors.rightMargin: root.cornerRadius
        height: 1
        color: Theme.glassPanelHighlight
        opacity: root.backdropAvailable ? 0.56 : 0.2
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: root.cornerRadius
        anchors.rightMargin: root.cornerRadius
        height: 1
        color: Theme.surfaceDepthEdge
        opacity: 0.55
    }
}
