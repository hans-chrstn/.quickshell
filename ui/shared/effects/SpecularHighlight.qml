import QtQuick

ShaderEffect {
    id: root
    
    anchors.fill: parent
    
    property vector2d mousePos: Qt.vector2d(0.5, 0.5)
    property real intensity: 0.0

    vertexShader: Qt.resolvedUrl("shaders/specular.vert.qsb")
    fragmentShader: Qt.resolvedUrl("shaders/specular.frag.qsb")
    
    Behavior on intensity {
        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
    }
}
