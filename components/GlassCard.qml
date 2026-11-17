import QtQuick
import QtQuick.Effects
import qs.core
import qs.components

Item {
    id: root

    property real cornerRadius: Design.radiusPanel
    property bool backdropAvailable: true
    property real emphasis: 1

    layer.enabled: visible
    layer.effect: MultiEffect {
        maskEnabled: true
        maskSpreadAtMin: 1
        maskThresholdMin: 0.5
        maskSource: ShaderEffectSource {
            sourceItem: Rectangle {
                width: root.width
                height: root.height
                radius: root.cornerRadius
                color: Theme.textPrimary
            }
        }
    }

    GlassPanelSurface {
        anchors.fill: parent
        cornerRadius: root.cornerRadius
        backdropAvailable: root.backdropAvailable
        emphasis: root.emphasis
    }
}
