import QtQuick

ShaderEffect {
    id: root

    property alias source: root.sourceItem
    property Item sourceItem

    vertexShader: Qt.resolvedUrl("shaders/default.vert.qsb")
    fragmentShader: Qt.resolvedUrl("shaders/vignette.frag.qsb")
}
