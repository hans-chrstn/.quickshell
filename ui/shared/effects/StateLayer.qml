import QtQuick
import qs.core

ShaderEffect {
    id: root
    
    anchors.fill: parent
    
    property color color: ThemeManager.visualHighlightColor
    property real cornerRadius: 0
    property bool isPressed: false
    property real mouseX: width / 2
    property real mouseY: height / 2
    
    property real currentRippleAlpha: 0.0
    property real currentRippleSize: 0.0
    property real targetRippleSize: Math.sqrt(width * width + height * height)
    
    property vector2d rippleCenter: Qt.vector2d(width / 2, height / 2)

    property real uWidth: root.width
    property real uHeight: root.height
    property real radius: root.cornerRadius
    property real rippleSize: currentRippleSize
    property real rippleAlpha: currentRippleAlpha
    property color baseColor: root.color

    vertexShader: Qt.resolvedUrl("shaders/statelayer.vert.qsb")
    fragmentShader: Qt.resolvedUrl("shaders/statelayer.frag.qsb")

    ParallelAnimation {
        id: rippleAnimation
        NumberAnimation {
            target: root
            property: "currentRippleSize"
            from: 0
            to: root.targetRippleSize
            duration: 650
            easing.type: Easing.OutQuart
        }
        NumberAnimation {
            target: root
            property: "currentRippleAlpha"
            from: 1.0
            to: 0.0
            duration: 750
            easing.type: Easing.OutSine
        }
    }

    onIsPressedChanged: {
        if (isPressed) {
            rippleCenter = Qt.vector2d(root.mouseX, root.mouseY)
            rippleAnimation.restart()
        }
    }
}
