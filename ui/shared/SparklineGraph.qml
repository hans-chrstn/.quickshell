import QtQuick
import qs.core

Item {
    id: root

    property var dataHistory: []
    property color lineColor: ThemeManager.accentColor
    property real maxValue: 100.0
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

            let w = width
            let h = height
            let count = root.dataHistory.length
            let maxItems = ProcessManager.maxHistory
            let step = w / (maxItems - 1)

            ctx.beginPath()
            ctx.lineWidth = root.lineWidth
            ctx.lineCap = "round"
            ctx.lineJoin = "round"
            ctx.strokeStyle = root.lineColor

            function getY(val) {
                let norm = Math.min(1.0, val / root.maxValue)
                return h - (norm * (h - 8)) - 4
            }

            ctx.beginPath()
            ctx.lineWidth = root.lineWidth
            ctx.lineCap = "round"
            ctx.lineJoin = "round"
            ctx.strokeStyle = root.lineColor

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
                gradient.addColorStop(0, Qt.rgba(lineColor.r, lineColor.g, lineColor.b, 0.25))
                gradient.addColorStop(0.6, Qt.rgba(lineColor.r, lineColor.g, lineColor.b, 0.08))
                gradient.addColorStop(1, Qt.rgba(lineColor.r, lineColor.g, lineColor.b, 0.0))
                
                ctx.fillStyle = gradient
                ctx.fill()
            }
        }
    }
}
