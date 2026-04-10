import QtQuick
import qs.core
import qs.core.auth

Item {
    id: root

    implicitWidth: 120

    implicitHeight: 120

    readonly property string seed: AuthManager.currentUser

    onSeedChanged: {
        canvas.requestPaint()
    }

    Canvas {
        id: canvas

        anchors.fill: parent

        onPaint: {
            let ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            
            let centerX = width / 2
            let centerY = height / 2
            
            let hash = 0
            for (let i = 0; i < root.seed.length; i++) {
                hash = ((hash << 5) - hash) + root.seed.charCodeAt(i)
                hash |= 0
            }
            
            function seededRandom(s) {
                let x = Math.sin(s++) * 10000
                return x - Math.floor(x)
            }
            
            let prng = hash
            
            ctx.strokeStyle = ThemeManager.accentColor
            ctx.lineWidth = 1
            ctx.lineCap = "round"
            
            for (let i = 0; i < 15; i++) {
                let radius = 10 + (i * 4)
                let startAngle = seededRandom(prng++) * Math.PI * 2
                let span = 0.5 + (seededRandom(prng++) * Math.PI)
                
                ctx.beginPath()
                ctx.arc(
                    centerX, 
                    centerY, 
                    radius, 
                    startAngle, 
                    startAngle + span
                )
                
                ctx.globalAlpha = 0.2 + (seededRandom(prng++) * 0.6)
                ctx.stroke()
            }
            
            ctx.lineWidth = 2
            for (let j = 0; j < 5; j++) {
                let r = 20 + (seededRandom(prng++) * 30)
                let a = seededRandom(prng++) * Math.PI * 2
                
                let dotX = centerX + Math.cos(a) * r
                let dotY = centerY + Math.sin(a) * r
                
                ctx.beginPath()
                ctx.moveTo(centerX, centerY)
                ctx.lineTo(dotX, dotY)
                ctx.globalAlpha = 0.1
                ctx.stroke()
                
                ctx.beginPath()
                ctx.rect(dotX - 2, dotY - 2, 4, 4)
                ctx.globalAlpha = 0.8
                ctx.fillStyle = ThemeManager.accentColor
                ctx.fill()
            }
            
            ctx.globalAlpha = 0.05
            ctx.beginPath()
            ctx.arc(centerX, centerY, 50, 0, Math.PI * 2)
            ctx.stroke()
        }
    }
}
