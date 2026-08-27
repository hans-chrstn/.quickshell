import QtQuick
import qs.core

Canvas {
    id: root

    property string name: "apps"
    property color glyphColor: Design.textMuted

    implicitWidth: 16
    implicitHeight: 16

    onNameChanged: requestPaint()
    onGlyphColorChanged: requestPaint()
    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        ctx.strokeStyle = root.glyphColor
        ctx.fillStyle = root.glyphColor
        ctx.lineWidth = 1.45
        ctx.lineCap = "round"
        ctx.lineJoin = "round"

        if (root.name === "apps") {
            const points = [4.5, 11.5]
            for (let x of points) {
                for (let y of points) {
                    ctx.beginPath()
                    ctx.arc(x, y, 1.35, 0, Math.PI * 2)
                    ctx.fill()
                }
            }
        } else if (root.name === "power") {
            ctx.beginPath()
            ctx.moveTo(8, 2.2)
            ctx.lineTo(8, 7.7)
            ctx.stroke()
            ctx.beginPath()
            ctx.arc(8, 8.3, 5.4, -0.78, Math.PI + 0.78)
            ctx.stroke()
        } else if (root.name === "settings") {
            for (let i = 0; i < 8; ++i) {
                const angle = i * Math.PI / 4
                ctx.beginPath()
                ctx.moveTo(8 + Math.cos(angle) * 5.1,
                    8 + Math.sin(angle) * 5.1)
                ctx.lineTo(8 + Math.cos(angle) * 6.7,
                    8 + Math.sin(angle) * 6.7)
                ctx.stroke()
            }
            ctx.beginPath()
            ctx.arc(8, 8, 5.2, 0, Math.PI * 2)
            ctx.stroke()
            ctx.beginPath()
            ctx.arc(8, 8, 1.8, 0, Math.PI * 2)
            ctx.stroke()
        }
    }
}
