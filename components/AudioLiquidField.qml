import QtQuick
import qs.core

Item {
    id: root

    property bool active: false
    property real peak: 0
    property real cornerRadius: 32
    property color tintColor: Theme.accent
    property real intensity: 1
    property real phase: 0
    property real level: 0

    Timer {
        interval: Design.audioLiquidFrameInterval
        repeat: true
        running: root.active && root.visible && !Design.reducedMotion
        onTriggered: {
            root.phase += Design.audioLiquidPhaseStep;
            root.level += (Math.max(0, Math.min(1, root.peak)) - root.level) * Design.audioLiquidResponse;
            field.requestPaint();
        }
    }

    Canvas {
        id: field
        anchors.fill: parent
        visible: root.active
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onVisibleChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            const w = width;
            const h = height;
            ctx.reset();
            if (!root.active || w <= 0 || h <= 0)
                return;

            const radius = Math.min(root.cornerRadius, w / 2, h / 2);
            ctx.beginPath();
            ctx.moveTo(radius, 0);
            ctx.lineTo(w - radius, 0);
            ctx.quadraticCurveTo(w, 0, w, radius);
            ctx.lineTo(w, h - radius);
            ctx.quadraticCurveTo(w, h, w - radius, h);
            ctx.lineTo(radius, h);
            ctx.quadraticCurveTo(0, h, 0, h - radius);
            ctx.lineTo(0, radius);
            ctx.quadraticCurveTo(0, 0, radius, 0);
            ctx.closePath();
            ctx.clip();

            const amplitude = Design.audioLiquidBaseAmplitude + root.level * Design.audioLiquidPeakAmplitude;
            const opacity = Math.max(0, Math.min(1, root.intensity));
            const waves = [
                {
                    base: 0.59,
                    scale: 1,
                    phase: 0,
                    alpha: Design.audioLiquidUpperOpacity
                },
                {
                    base: 0.77,
                    scale: 0.72,
                    phase: 2.1,
                    alpha: Design.audioLiquidLowerOpacity
                }
            ];

            for (const wave of waves) {
                ctx.beginPath();
                ctx.moveTo(0, h);
                for (let x = 0; x <= w + 3; x += 3) {
                    const position = x / w;
                    const drift = Math.sin(position * Math.PI * 2.7 - root.phase + wave.phase);
                    const ripple = Math.sin(position * Math.PI * 5.2 + root.phase * 0.55 + wave.phase) * 0.3;
                    const y = h * wave.base + (drift + ripple) * amplitude * wave.scale;
                    ctx.lineTo(x, y);
                }
                ctx.lineTo(w, h);
                ctx.closePath();
                const fill = ctx.createLinearGradient(0, 0, 0, h);
                fill.addColorStop(0, Theme.alpha(root.tintColor, 0));
                fill.addColorStop(1, Theme.alpha(root.tintColor, wave.alpha * opacity));
                ctx.fillStyle = fill;
                ctx.fill();
            }
        }
    }
}
