import QtQuick
import QtQuick.Effects
import qs.components
import qs.core

Item {
    id: root

    property string sourceUrl: ""
    property real cornerRadius: Design.radiusGrouped
    readonly property bool hasArtwork: artwork.status === Image.Ready

    Rectangle {
        anchors.fill: parent
        radius: root.cornerRadius
        color: Theme.fillElevated
        border.color: Theme.glassPanelStroke
    }

    Image {
        id: artwork
        anchors.fill: parent
        source: root.sourceUrl
        sourceSize.width: Math.max(1, Math.ceil(width * 1.5))
        sourceSize.height: Math.max(1, Math.ceil(height * 1.5))
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: source.toString().length > 0
        opacity: root.hasArtwork ? 1 : 0
        layer.enabled: visible
        Behavior on opacity {
            NumberAnimation {
                duration: Design.springContentFadeInDuration
                easing.type: Design.motionStandardEasing
            }
        }
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSpreadAtMin: 1
            maskThresholdMin: 0.5
            maskSource: ShaderEffectSource {
                sourceItem: Rectangle {
                    width: artwork.width
                    height: artwork.height
                    radius: root.cornerRadius
                    color: Theme.textPrimary
                }
            }
        }
    }

    IslandGlyph {
        anchors.centerIn: parent
        width: Math.min(parent.width, parent.height) * 0.35
        height: width
        name: "music"
        glyphColor: Theme.accent
        opacity: root.hasArtwork ? 0 : 1
        Behavior on opacity {
            NumberAnimation {
                duration: Design.springContentFadeInDuration
                easing.type: Design.motionStandardEasing
            }
        }
    }
}
