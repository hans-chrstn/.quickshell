import QtQuick

ShaderEffect {
    id: root

    property real intensity: 0.05
    property real time: 0.0

    Timer {
        interval: 48
        running: true
        repeat: true
        onTriggered: {
            root.time = Math.random()
        }
    }

    vertexShader: Qt.resolvedUrl("shaders/noise.vert.qsb")
    fragmentShader: Qt.resolvedUrl("shaders/noise.frag.qsb")
}
