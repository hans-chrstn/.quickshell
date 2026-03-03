import QtQuick
import QtQuick.Effects

Item {
    id: root

    property alias source: blur.source
    property real blurRadius: 32.0
    property real chromaticIntensity: 0.002
    property real grainIntensity: 0.0
    property color overlayColor: "#000000"
    property real overlayOpacity: 0.6

    KawaseBlur {
        id: blur
        anchors.fill: parent
        radius: root.blurRadius
    }

    ChromaticAberration {
        id: chromatic
        anchors.fill: parent
        source: blur
        intensity: root.chromaticIntensity
    }

    Vignette {
        id: vignette
        anchors.fill: parent
        source: chromatic
    }

    Rectangle {
        id: overlay
        anchors.fill: parent
        color: root.overlayColor
        opacity: root.overlayOpacity
    }
}
