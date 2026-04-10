import QtQuick
import qs.core
import qs.core.auth

Item {
    id: root

    implicitWidth: 120

    implicitHeight: 120

    readonly property string seed: AuthManager.currentUser

    property bool active: false

    property int frame: 0

    property var sparks: []

    onSeedChanged: {
        canvas.requestPaint()
    }

    Timer {
        id: animationTimer

        interval: 33

        repeat: true

        running: root.active

        onTriggered: {
            root.frame++
            
            if (root.sparks.length < 5) {
                root.sparks.push({
                    angle: Math.random() * Math.PI * 2,
                    life: 1.0,
                    speed: 0.1 + (Math.random() * 0.2)
                })
            }

            for (let i = root.sparks.length - 1; i >= 0; i--) {
                root.sparks[i].life -= root.sparks[i].speed
                if (root.sparks[i].life <= 0) {
                    root.sparks.splice(i, 1)
                }
            }

            canvas.requestPaint()
        }
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
                
                if (root.active) {
                    radius += (seededRandom(root.frame + i) - 0.5) * 2
                }

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

            if (root.active) {
                ctx.lineWidth = 1
                ctx.strokeStyle = "white"
                for (let k = 0; k < root.sparks.length; k++) {
                    let s = root.sparks[k]
                    let len = 30 + (s.life * 40)
                    
                    ctx.beginPath()
                    ctx.moveTo(centerX, centerY)
                    ctx.lineTo(
                        centerX + Math.cos(s.angle) * len, 
                        centerY + Math.sin(s.angle) * len
                    )
                    ctx.globalAlpha = s.life * 0.5
                    ctx.stroke()
                    
                    ctx.beginPath()
                    ctx.rect(
                        centerX + Math.cos(s.angle) * len - 1,
                        centerY + Math.sin(s.angle) * len - 1,
                        2, 
                        2
                    )
                    ctx.fillStyle = "white"
                    ctx.globalAlpha = s.life
                    ctx.fill()
                }
            }
            
            ctx.strokeStyle = ThemeManager.accentColor
            ctx.globalAlpha = 0.05
            ctx.beginPath()
            ctx.arc(centerX, centerY, 50, 0, Math.PI * 2)
            ctx.stroke()
        }
    }
}
