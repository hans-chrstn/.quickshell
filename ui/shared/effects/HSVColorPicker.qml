import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.core
import qs.ui.shared

Item {
    id: root
    
    property color currentColor: "#FFFFFF"
    
    signal colorChanged(color newColor)

    property real h: 0.0
    property real s: 0.0
    property real v: 1.0

    width: 280
    height: 200

    function updateFromColor(col) {
        let hsv = root.rgbToHsv(col.r, col.g, col.b)
        h = hsv.h
        s = hsv.s
        v = hsv.v
    }

    function rgbToHsv(r, g, b) {
        let max = Math.max(r, g, b), min = Math.min(r, g, b)
        let h, s, v = max
        let d = max - min
        s = max === 0 ? 0 : d / max
        if (max === min) {
            h = 0
        } else {
            switch (max) {
                case r: h = (g - b) / d + (g < b ? 6 : 0); break
                case g: h = (b - r) / d + 2; break
                case b: h = (r - g) / d + 4; break
            }
            h /= 6
        }
        return { h: h, s: s, v: v }
    }

    function hsvToRgb(h, s, v) {
        let r, g, b
        let i = Math.floor(h * 6)
        let f = h * 6 - i
        let p = v * (1 - s)
        let q = v * (1 - f * s)
        let t = v * (1 - (1 - f) * s)
        switch (i % 6) {
            case 0: r = v, g = t, b = p; break
            case 1: r = q, g = v, b = p; break
            case 2: r = p, g = v, b = t; break
            case 3: r = p, g = q, b = v; break
            case 4: r = t, g = p, b = v; break
            case 5: r = v, g = p, b = q; break
        }
        return Qt.rgba(r, g, b, 1.0)
    }

    onHChanged: root.currentColor = root.hsvToRgb(h, s, v)
    onSChanged: root.currentColor = root.hsvToRgb(h, s, v)
    onVChanged: root.currentColor = root.hsvToRgb(h, s, v)
    
    onCurrentColorChanged: {
        root.colorChanged(currentColor)
    }

    RowLayout {
        anchors.fill: parent
        spacing: 16

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            ClippingRectangle {
                anchors.fill: parent
                radius: 12
                color: "black"

                ShaderEffect {
                    anchors.fill: parent
                    property real hue: root.h
                    vertexShader: Qt.resolvedUrl("shaders/hsv.vert.qsb")
                    fragmentShader: Qt.resolvedUrl("shaders/hsv.frag.qsb")
                }

                MouseArea {
                    anchors.fill: parent
                    preventStealing: true
                    function handleInput(mouse) {
                        root.s = Math.max(0, Math.min(1, mouse.x / width))
                        root.v = Math.max(0, Math.min(1, 1.0 - (mouse.y / height)))
                    }
                    onPressed: (mouse) => handleInput(mouse)
                    onPositionChanged: (mouse) => { if (pressed) handleInput(mouse) }
                }

                Rectangle {
                    x: (root.s * parent.width) - 8
                    y: ((1.0 - root.v) * parent.height) - 8
                    width: 16
                    height: 16
                    radius: 8
                    color: "transparent"
                    border.color: "white"
                    border.width: 2
                    
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 2
                        radius: 6
                        color: "transparent"
                        border.color: "black"
                        border.width: 1
                        opacity: 0.5
                    }
                }
            }
        }

        Item {
            Layout.preferredWidth: 30
            Layout.fillHeight: true

            ClippingRectangle {
                anchors.fill: parent
                radius: 15
                
                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#ff0000" }
                        GradientStop { position: 0.17; color: "#ffff00" }
                        GradientStop { position: 0.33; color: "#00ff00" }
                        GradientStop { position: 0.5; color: "#00ffff" }
                        GradientStop { position: 0.67; color: "#0000ff" }
                        GradientStop { position: 0.83; color: "#ff00ff" }
                        GradientStop { position: 1.0; color: "#ff0000" }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    preventStealing: true
                    function handleInput(mouse) {
                        root.h = Math.max(0, Math.min(1, mouse.y / height))
                    }
                    onPressed: (mouse) => handleInput(mouse)
                    onPositionChanged: (mouse) => { if (pressed) handleInput(mouse) }
                }

                Rectangle {
                    y: (root.h * parent.height) - 4
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 8
                    radius: 4
                    color: "white"
                    border.color: "black"
                    border.width: 1
                    opacity: 0.8
                }
            }
        }
    }
}
