import QtQuick

Item {
    id: root

    property alias source: root.sourceItem
    property Item sourceItem
    property real radius: 4.0

    ShaderEffectSource {
        id: pass1Source
        sourceItem: root.sourceItem
        hideSource: true
        live: true
        smooth: true
    }

    ShaderEffect {
        id: pass1
        anchors.fill: parent
        property variant source: pass1Source
        property real offset: 0.5 * root.radius
        
        vertexShader: Qt.resolvedUrl("shaders/kawase.vert.qsb")
        fragmentShader: Qt.resolvedUrl("shaders/kawase.frag.qsb")
        visible: false
    }

    ShaderEffectSource {
        id: pass2Source
        sourceItem: pass1
        live: true
        smooth: true
        visible: false
    }

    ShaderEffect {
        id: pass2
        anchors.fill: parent
        property variant source: pass2Source
        property real offset: 1.5 * root.radius
        
        vertexShader: Qt.resolvedUrl("shaders/kawase.vert.qsb")
        fragmentShader: Qt.resolvedUrl("shaders/kawase.frag.qsb")
        visible: false
    }

    ShaderEffectSource {
        id: pass3Source
        sourceItem: pass2
        live: true
        smooth: true
        visible: false
    }

    ShaderEffect {
        id: pass3
        anchors.fill: parent
        property variant source: pass3Source
        property real offset: 2.5 * root.radius
        
        vertexShader: Qt.resolvedUrl("shaders/kawase.vert.qsb")
        fragmentShader: Qt.resolvedUrl("shaders/kawase.frag.qsb")
        visible: false
    }

    ShaderEffectSource {
        id: pass4Source
        sourceItem: pass3
        live: true
        smooth: true
        visible: false
    }

    ShaderEffect {
        id: pass4
        anchors.fill: parent
        property variant source: pass4Source
        property real offset: 3.5 * root.radius
        
        vertexShader: Qt.resolvedUrl("shaders/kawase.vert.qsb")
        fragmentShader: Qt.resolvedUrl("shaders/kawase.frag.qsb")
        visible: false
    }

    ShaderEffectSource {
        id: pass5Source
        sourceItem: pass4
        live: true
        smooth: true
        visible: false
    }

    ShaderEffect {
        id: pass5
        anchors.fill: parent
        property variant source: pass5Source
        property real offset: 4.5 * root.radius
        
        vertexShader: Qt.resolvedUrl("shaders/kawase.vert.qsb")
        fragmentShader: Qt.resolvedUrl("shaders/kawase.frag.qsb")
    }
}
