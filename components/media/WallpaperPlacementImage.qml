import QtQuick
import QtQuick.Effects
import qs.core

Item {
    id: root

    required property string path
    property var placement: ({
            zoom: 1,
            panX: 0,
            panY: 0,
            rotation: 0
        })
    property real renderScale: 1
    property real cornerRadius: 0
    readonly property real zoom: Math.max(1, Math.min(3, Number(placement?.zoom) || 1))
    readonly property int rotationAngle: Number(placement?.rotation) || 0
    readonly property bool quarterTurn: rotationAngle === 90 || rotationAngle === 270
    readonly property real maximumPanX: width * (zoom - 1) / 2
    readonly property real maximumPanY: height * (zoom - 1) / 2
    readonly property bool ready: image.status === Image.Ready
    readonly property int status: image.status

    clip: true
    layer.enabled: cornerRadius > 0
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

    Image {
        id: image
        anchors.centerIn: parent
        width: (root.quarterTurn ? root.height : root.width) * root.zoom
        height: (root.quarterTurn ? root.width : root.height) * root.zoom
        source: LocalUrl.fromPath(root.path)
        sourceSize.width: Math.max(1, Math.ceil(width * root.renderScale))
        sourceSize.height: Math.max(1, Math.ceil(height * root.renderScale))
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        rotation: root.rotationAngle
        visible: status === Image.Ready

        transform: Translate {
            x: Math.max(-1, Math.min(1, Number(root.placement?.panX) || 0)) * root.maximumPanX
            y: Math.max(-1, Math.min(1, Number(root.placement?.panY) || 0)) * root.maximumPanY
        }
    }
}
