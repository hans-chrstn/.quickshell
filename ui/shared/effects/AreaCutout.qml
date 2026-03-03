import QtQuick
import qs.core

ShaderEffect {
    id: root
    
    anchors.fill: parent
    
    property rect selection: AreaPickerManager.selection
    
    property vector4d rect: Qt.vector4d(
        selection.x / width,
        selection.y / height,
        selection.width / width,
        selection.height / height
    )

    vertexShader: Qt.resolvedUrl("shaders/cutout.vert.qsb")
    fragmentShader: Qt.resolvedUrl("shaders/cutout.frag.qsb")
}
