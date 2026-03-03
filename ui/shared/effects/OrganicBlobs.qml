import QtQuick

ShaderEffect {
    id: root

    property color color1: "#ff0000"
    property color color2: "#00ff00"
    property color color3: "#0000ff"
    property real time: 0.0

    Timer {
        interval: 16
        running: true
        repeat: true
        onTriggered: {
            root.time += 0.01
        }
    }

    vertexShader: Qt.resolvedUrl("shaders/blobs.vert.qsb")
    fragmentShader: Qt.resolvedUrl("shaders/blobs.frag.qsb")
}
