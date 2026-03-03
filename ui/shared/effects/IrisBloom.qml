import QtQuick

Item {
    id: root
    
    property alias source: effectSource.sourceItem
    property real progress: 0.0
    property real cornerRadius: 0

    ShaderEffectSource {
        id: effectSource
        anchors.fill: parent
        hideSource: true
        live: true
        smooth: true
        visible: false
    }

    ShaderEffect {
        id: bloomShader
        anchors.fill: parent
        
        property variant source: effectSource
        property real progress: root.progress
        property real uWidth: root.width
        property real uHeight: root.height
        property real radius: root.cornerRadius
        property real aspectRatio: root.width / root.height

        vertexShader: Qt.resolvedUrl("shaders/iris.vert.qsb")
        fragmentShader: Qt.resolvedUrl("shaders/iris.frag.qsb")
    }
    
    Behavior on progress {
        NumberAnimation {
            duration: 600
            easing.type: Easing.OutQuart
        }
    }
}
