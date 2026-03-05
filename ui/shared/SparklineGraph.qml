import QtQuick
import qs.core

Item {
    id: root

    property var dataHistory: []
    property color lineColor: ThemeManager.accentColor
    property real maxValue: 100.0
    property bool autoScale: true
    property bool showFill: true
    property real lineWidth: 2.0

    onDataHistoryChanged: {
        canvas.requestPaint()
    }

    Canvas {
        id: canvas
        anchors.fill: parent
        antialiasing: true
        renderTarget: Canvas.FramebufferObject
        
        onPaint: {
            let ctx = getContext("2d")
            ctx.reset()
            
            if (root.dataHistory.length < 2) {
                return
            }

            let c = Qt.color(root.lineColor)
            let w = width
            let h = height
            let count = root.dataHistory.length
            let maxItems = ProcessManager.maxHistory
            let step = w / (maxItems - 1)

            let currentMax = 0.1
            for (let i = 0; i < count; i++) {
                if (root.dataHistory[i] > currentMax) currentMax = root.dataHistory[i]
            }
            
            let effectiveMax = root.autoScale ? Math.max(currentMax * 1.2, 1.0) : root.maxValue

            function getY(val) {
                let norm = Math.min(1.0, val / effectiveMax)
                return h - (norm * (h - 12)) - 6
            }

            ctx.beginPath()
            ctx.lineWidth = root.lineWidth
            ctx.lineCap = "round"
            ctx.lineJoin = "round"
            ctx.strokeStyle = c

            for (let i = 0; i < count; i++) {
                let x = (w - (count - 1 - i) * step)
                let y = getY(root.dataHistory[i])
                if (i === 0) ctx.moveTo(x, y)
                else ctx.lineTo(x, y)
            }
            ctx.stroke()

            if (root.showFill) {
                ctx.beginPath()
                let firstX = w - (count - 1) * step
                let firstY = getY(root.dataHistory[0])
                
                ctx.moveTo(firstX, firstY)
                for (let i = 1; i < count; i++) {
                    let x = (w - (count - 1 - i) * step)
                    let y = getY(root.dataHistory[i])
                    ctx.lineTo(x, y)
                }

                ctx.lineTo(w, h)
                ctx.lineTo(firstX, h)
                ctx.closePath()
                
                let gradient = ctx.createLinearGradient(0, 0, 0, h)
                gradient.addColorStop(0, Qt.rgba(c.r, c.g, c.b, 0.25))
                gradient.addColorStop(0.7, Qt.rgba(c.r, c.g, c.b, 0.1))
                gradient.addColorStop(1, Qt.rgba(c.r, c.g, c.b, 0.02))
                
                ctx.fillStyle = gradient
                ctx.fill()
            }
        }
    }
}
