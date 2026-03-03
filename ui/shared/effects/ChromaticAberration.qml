import QtQuick

ShaderEffect {
    id: root

    property alias source: root.sourceItem
    property Item sourceItem
    property real intensity: 0.01

    vertexShader: Qt.resolvedUrl("shaders/chromatic.vert.qsb")
    fragmentShader: Qt.resolvedUrl("shaders/chromatic.frag.qsb")
}
