import QtQuick
import qs.core

ShaderEffect {
    id: root
    
    anchors.fill: parent
    
    property color baseColor: ThemeManager.accentColor
    property real time: 0.0
    property real intensity: 0.0

    vertexShader: Qt.resolvedUrl("shaders/liquid.vert.qsb")
    fragmentShader: Qt.resolvedUrl("shaders/liquid.frag.qsb")
    
    Timer {
        interval: 16
        running: parent.visible
        repeat: true
        onTriggered: {
            root.time += 0.05
        }
    }
    
    Behavior on intensity {
        NumberAnimation {
            duration: 100
            easing.type: Easing.OutCubic
        }
    }
}
