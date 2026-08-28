import QtQuick
import QtQuick.Effects
import qs.core

Rectangle {
    id: root

    required property string path
    property bool selected: false
    signal activated()

    radius: 12
    color: Design.surface
    border.width: selected ? 2 : 1
    border.color: selected ? Design.blue : Design.separator
    clip: true
    scale: tap.pressed ? 0.975 : 1

    Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
    Behavior on border.color { ColorAnimation { duration: 120 } }

    Image {
        id: preview
        anchors.fill: parent
        anchors.margins: root.selected ? 3 : 2
        source: "file://" + root.path
        sourceSize.width: Math.ceil(width * 1.5)
        sourceSize.height: Math.ceil(height * 1.5)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSpreadAtMin: 1
            maskThresholdMin: 0.5
            maskSource: ShaderEffectSource {
                sourceItem: Rectangle {
                    width: preview.width
                    height: preview.height
                    radius: Math.max(0, root.radius - preview.anchors.margins)
                    color: "white"
                }
            }
        }
    }

    Rectangle {
        anchors.fill: preview
        radius: Math.max(0, root.radius - preview.anchors.margins)
        color: "#52000000"
        visible: preview.status !== Image.Ready || hover.hovered
        Behavior on opacity { NumberAnimation { duration: 120 } }
    }

    Text {
        anchors.centerIn: parent
        visible: preview.status !== Image.Ready
        text: preview.status === Image.Error ? "Unavailable" : "Loading"
        color: Design.textMuted
        font.family: Design.fontText
        font.pixelSize: 11
    }

    Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 8
        width: 18
        height: 18
        radius: 9
        visible: root.selected
        color: Design.blue

        Text {
            anchors.centerIn: parent
            text: "✓"
            color: Design.text
            font.pixelSize: 11
            font.weight: Font.Bold
        }
    }

    HoverHandler { id: hover }
    TapHandler {
        id: tap
        onTapped: root.activated()
    }
}
