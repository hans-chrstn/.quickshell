import QtQuick
import qs.core

Canvas {
    id: root

    property string name: "apps"
    property color glyphColor: Theme.textSecondary

    implicitWidth: 17
    implicitHeight: 17

    onNameChanged: requestPaint()
    onGlyphColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        const logicalSize = 17;
        const glyphScale = Math.max(0, Math.min(root.width, root.height) / logicalSize);
        ctx.translate((root.width - logicalSize * glyphScale) / 2, (root.height - logicalSize * glyphScale) / 2);
        ctx.scale(glyphScale, glyphScale);
        ctx.strokeStyle = root.glyphColor;
        ctx.fillStyle = root.glyphColor;
        ctx.lineWidth = 1.45;
        ctx.lineCap = "round";
        ctx.lineJoin = "round";

        if (root.name === "apps") {
            const points = [4, 8.5, 13];
            for (let x of points) {
                for (let y of points) {
                    ctx.beginPath();
                    ctx.arc(x, y, 1.15, 0, Math.PI * 2);
                    ctx.fill();
                }
            }
        } else if (root.name === "power") {
            ctx.beginPath();
            ctx.moveTo(8.5, 2.3);
            ctx.lineTo(8.5, 7.8);
            ctx.stroke();
            ctx.beginPath();
            ctx.arc(8.5, 8.5, 5.35, -0.78, Math.PI + 0.78);
            ctx.stroke();
        } else if (root.name === "settings") {
            for (let i = 0; i < 8; ++i) {
                const angle = i * Math.PI / 4;
                ctx.beginPath();
                ctx.moveTo(8.5 + Math.cos(angle) * 5.0, 8.5 + Math.sin(angle) * 5.0);
                ctx.lineTo(8.5 + Math.cos(angle) * 6.6, 8.5 + Math.sin(angle) * 6.6);
                ctx.stroke();
            }
            ctx.beginPath();
            ctx.arc(8.5, 8.5, 5.1, 0, Math.PI * 2);
            ctx.stroke();
            ctx.beginPath();
            ctx.arc(8.5, 8.5, 1.75, 0, Math.PI * 2);
            ctx.stroke();
        } else if (root.name === "chevronLeft" || root.name === "chevronRight") {
            const direction = root.name === "chevronLeft" ? -1 : 1;
            ctx.beginPath();
            ctx.moveTo(8.5 - direction * 2.5, 4.5);
            ctx.lineTo(8.5 + direction * 1.5, 8.5);
            ctx.lineTo(8.5 - direction * 2.5, 12.5);
            ctx.stroke();
        } else if (root.name === "folder") {
            ctx.beginPath();
            ctx.moveTo(2.2, 5.0);
            ctx.lineTo(6.4, 5.0);
            ctx.lineTo(7.7, 6.4);
            ctx.lineTo(14.8, 6.4);
            ctx.lineTo(14.8, 13.4);
            ctx.lineTo(2.2, 13.4);
            ctx.closePath();
            ctx.stroke();
        } else if (root.name === "document") {
            ctx.beginPath();
            ctx.moveTo(4.0, 2.3);
            ctx.lineTo(10.2, 2.3);
            ctx.lineTo(13.8, 5.9);
            ctx.lineTo(13.8, 14.7);
            ctx.lineTo(4.0, 14.7);
            ctx.closePath();
            ctx.moveTo(10.2, 2.3);
            ctx.lineTo(10.2, 5.9);
            ctx.lineTo(13.8, 5.9);
            ctx.stroke();
        } else if (root.name === "edit") {
            ctx.beginPath();
            ctx.moveTo(4.4, 3.0);
            ctx.lineTo(11.6, 3.0);
            ctx.quadraticCurveTo(13.6, 3.0, 13.6, 5.0);
            ctx.lineTo(13.6, 12.2);
            ctx.quadraticCurveTo(13.6, 14.2, 11.6, 14.2);
            ctx.lineTo(4.4, 14.2);
            ctx.quadraticCurveTo(2.4, 14.2, 2.4, 12.2);
            ctx.lineTo(2.4, 5.0);
            ctx.quadraticCurveTo(2.4, 3.0, 4.4, 3.0);
            ctx.stroke();
            ctx.beginPath();
            ctx.moveTo(5.0, 11.8);
            ctx.lineTo(5.7, 9.2);
            ctx.lineTo(11.6, 3.3);
            ctx.lineTo(13.2, 4.9);
            ctx.lineTo(7.3, 10.8);
            ctx.closePath();
            ctx.stroke();
        } else if (root.name === "crop") {
            ctx.beginPath();
            ctx.moveTo(5.0, 2.3);
            ctx.lineTo(5.0, 11.9);
            ctx.quadraticCurveTo(5.0, 12.8, 6.0, 12.8);
            ctx.lineTo(14.8, 12.8);
            ctx.moveTo(2.3, 5.0);
            ctx.lineTo(11.9, 5.0);
            ctx.quadraticCurveTo(12.8, 5.0, 12.8, 6.0);
            ctx.lineTo(12.8, 14.8);
            ctx.stroke();
        } else if (root.name === "rotate") {
            ctx.beginPath();
            ctx.arc(8.5, 8.5, 5.3, -2.3, 2.2);
            ctx.moveTo(3.7, 5.7);
            ctx.lineTo(4.0, 2.6);
            ctx.lineTo(7.0, 3.3);
            ctx.stroke();
        } else if (root.name === "plus") {
            ctx.beginPath();
            ctx.moveTo(8.5, 3.3);
            ctx.lineTo(8.5, 13.7);
            ctx.moveTo(3.3, 8.5);
            ctx.lineTo(13.7, 8.5);
            ctx.stroke();
        } else if (root.name === "close") {
            ctx.beginPath();
            ctx.moveTo(4.2, 4.2);
            ctx.lineTo(12.8, 12.8);
            ctx.moveTo(12.8, 4.2);
            ctx.lineTo(4.2, 12.8);
            ctx.stroke();
        } else if (root.name === "checkmark") {
            ctx.lineWidth = 1.8;
            ctx.beginPath();
            ctx.moveTo(3.6, 8.8);
            ctx.lineTo(7.1, 12.0);
            ctx.lineTo(13.7, 5.0);
            ctx.stroke();
        } else if (root.name === "search") {
            ctx.beginPath();
            ctx.arc(7.2, 7.2, 4.3, 0, Math.PI * 2);
            ctx.moveTo(10.5, 10.5);
            ctx.lineTo(14.4, 14.4);
            ctx.stroke();
        } else if (root.name === "more") {
            ctx.beginPath();
            ctx.arc(3.8, 8.5, 1.25, 0, Math.PI * 2);
            ctx.arc(8.5, 8.5, 1.25, 0, Math.PI * 2);
            ctx.arc(13.2, 8.5, 1.25, 0, Math.PI * 2);
            ctx.fill();
        } else if (root.name === "wifi") {
            ctx.beginPath();
            ctx.arc(8.5, 12.4, 0.9, 0, Math.PI * 2);
            ctx.fill();
            ctx.beginPath();
            ctx.arc(8.5, 13.8, 4.6, Math.PI * 1.22, Math.PI * 1.78);
            ctx.arc(8.5, 13.8, 8.2, Math.PI * 1.22, Math.PI * 1.78);
            ctx.stroke();
        } else if (root.name === "ethernet") {
            ctx.beginPath();
            ctx.moveTo(4.1, 2.5);
            ctx.lineTo(12.9, 2.5);
            ctx.lineTo(12.9, 8.2);
            ctx.lineTo(10.6, 10.5);
            ctx.lineTo(6.4, 10.5);
            ctx.lineTo(4.1, 8.2);
            ctx.closePath();
            ctx.moveTo(6.4, 10.5);
            ctx.lineTo(6.4, 14.4);
            ctx.moveTo(10.6, 10.5);
            ctx.lineTo(10.6, 14.4);
            ctx.moveTo(3.5, 14.4);
            ctx.lineTo(13.5, 14.4);
            ctx.moveTo(6.4, 5.1);
            ctx.lineTo(6.4, 7.3);
            ctx.moveTo(8.5, 5.1);
            ctx.lineTo(8.5, 7.3);
            ctx.moveTo(10.6, 5.1);
            ctx.lineTo(10.6, 7.3);
            ctx.stroke();
        } else if (root.name === "headphones") {
            ctx.beginPath();
            ctx.arc(8.5, 8.4, 5.5, Math.PI, 0);
            ctx.moveTo(3.0, 8.4);
            ctx.lineTo(3.0, 13.2);
            ctx.quadraticCurveTo(3.0, 14.4, 4.2, 14.4);
            ctx.lineTo(5.3, 14.4);
            ctx.quadraticCurveTo(6.1, 14.4, 6.1, 13.5);
            ctx.lineTo(6.1, 10.7);
            ctx.quadraticCurveTo(6.1, 9.8, 5.3, 9.8);
            ctx.lineTo(3.0, 9.8);
            ctx.moveTo(14.0, 8.4);
            ctx.lineTo(14.0, 13.2);
            ctx.quadraticCurveTo(14.0, 14.4, 12.8, 14.4);
            ctx.lineTo(11.7, 14.4);
            ctx.quadraticCurveTo(10.9, 14.4, 10.9, 13.5);
            ctx.lineTo(10.9, 10.7);
            ctx.quadraticCurveTo(10.9, 9.8, 11.7, 9.8);
            ctx.lineTo(14.0, 9.8);
            ctx.stroke();
        } else if (root.name === "keyboard") {
            ctx.strokeRect(2.0, 4.0, 13.0, 9.5);
            ctx.beginPath();
            ctx.moveTo(4.0, 6.6);
            ctx.lineTo(4.6, 6.6);
            ctx.moveTo(6.4, 6.6);
            ctx.lineTo(7.0, 6.6);
            ctx.moveTo(8.8, 6.6);
            ctx.lineTo(9.4, 6.6);
            ctx.moveTo(11.2, 6.6);
            ctx.lineTo(11.8, 6.6);
            ctx.moveTo(4.0, 9.0);
            ctx.lineTo(4.6, 9.0);
            ctx.moveTo(6.4, 9.0);
            ctx.lineTo(7.0, 9.0);
            ctx.moveTo(8.8, 9.0);
            ctx.lineTo(9.4, 9.0);
            ctx.moveTo(11.2, 9.0);
            ctx.lineTo(11.8, 9.0);
            ctx.moveTo(5.0, 11.5);
            ctx.lineTo(12.0, 11.5);
            ctx.stroke();
        } else if (root.name === "bluetooth") {
            ctx.beginPath();
            ctx.moveTo(8.2, 2.0);
            ctx.lineTo(12.1, 5.6);
            ctx.lineTo(4.7, 12.2);
            ctx.moveTo(8.2, 15.0);
            ctx.lineTo(12.1, 11.4);
            ctx.lineTo(4.7, 4.8);
            ctx.moveTo(8.2, 2.0);
            ctx.lineTo(8.2, 15.0);
            ctx.stroke();
        } else if (root.name === "lock") {
            ctx.strokeRect(4.2, 7.7, 8.6, 6.9);
            ctx.beginPath();
            ctx.arc(8.5, 7.7, 3.0, Math.PI, 0);
            ctx.stroke();
        } else if (root.name === "music") {
            ctx.beginPath();
            ctx.moveTo(7.0, 12.0);
            ctx.lineTo(7.0, 4.2);
            ctx.lineTo(13.3, 2.8);
            ctx.lineTo(13.3, 10.3);
            ctx.stroke();
            ctx.beginPath();
            ctx.ellipse(4.8, 11.0, 3.8, 2.6, -0.2, 0, Math.PI * 2);
            ctx.ellipse(11.1, 9.3, 3.8, 2.6, -0.2, 0, Math.PI * 2);
            ctx.fill();
        } else if (root.name === "skipPrevious" || root.name === "skipNext") {
            const previous = root.name === "skipPrevious";
            ctx.fillRect(previous ? 3.1 : 12.5, 3.4, 1.5, 10.2);
            ctx.beginPath();
            if (previous) {
                ctx.moveTo(13.1, 3.4);
                ctx.lineTo(5.2, 8.5);
                ctx.lineTo(13.1, 13.6);
            } else {
                ctx.moveTo(3.9, 3.4);
                ctx.lineTo(11.8, 8.5);
                ctx.lineTo(3.9, 13.6);
            }
            ctx.closePath();
            ctx.fill();
        } else if (root.name === "launch") {
            ctx.beginPath();
            ctx.moveTo(3.0, 9.8);
            ctx.lineTo(3.0, 14.0);
            ctx.lineTo(11.1, 14.0);
            ctx.lineTo(11.1, 9.8);
            ctx.moveTo(7.0, 10.0);
            ctx.lineTo(14.0, 3.0);
            ctx.moveTo(8.5, 3.0);
            ctx.lineTo(14.0, 3.0);
            ctx.lineTo(14.0, 8.5);
            ctx.stroke();
        } else if (root.name === "bell" || root.name === "bellOff") {
            ctx.beginPath();
            ctx.moveTo(4.1, 11.6);
            ctx.bezierCurveTo(5.2, 10.6, 5.4, 9.3, 5.4, 7.1);
            ctx.bezierCurveTo(5.4, 4.8, 6.6, 3.2, 8.5, 3.2);
            ctx.bezierCurveTo(10.4, 3.2, 11.6, 4.8, 11.6, 7.1);
            ctx.bezierCurveTo(11.6, 9.3, 11.8, 10.6, 12.9, 11.6);
            ctx.closePath();
            ctx.stroke();
            ctx.beginPath();
            ctx.arc(8.5, 12.8, 1.3, 0, Math.PI);
            ctx.stroke();
            if (root.name === "bellOff") {
                ctx.beginPath();
                ctx.moveTo(2.7, 14.3);
                ctx.lineTo(14.3, 2.7);
                ctx.stroke();
            }
        } else if (root.name === "trash") {
            ctx.beginPath();
            ctx.moveTo(4.5, 4.7);
            ctx.lineTo(12.5, 4.7);
            ctx.lineTo(11.9, 14.0);
            ctx.lineTo(5.1, 14.0);
            ctx.closePath();
            ctx.moveTo(3.5, 4.7);
            ctx.lineTo(13.5, 4.7);
            ctx.moveTo(6.3, 3.1);
            ctx.lineTo(10.7, 3.1);
            ctx.stroke();
        } else if (root.name === "sun" || root.name === "moon" || root.name === "cloud" || root.name === "rain" || root.name === "snow" || root.name === "fog" || root.name === "storm" || root.name === "weatherUnavailable") {
            if (root.name === "sun") {
                ctx.beginPath();
                ctx.arc(8.5, 8.5, 3.1, 0, Math.PI * 2);
                ctx.stroke();
                for (let ray = 0; ray < 8; ++ray) {
                    const angle = ray * Math.PI / 4;
                    ctx.beginPath();
                    ctx.moveTo(8.5 + Math.cos(angle) * 5.2, 8.5 + Math.sin(angle) * 5.2);
                    ctx.lineTo(8.5 + Math.cos(angle) * 6.9, 8.5 + Math.sin(angle) * 6.9);
                    ctx.stroke();
                }
            } else if (root.name === "moon") {
                ctx.beginPath();
                ctx.arc(8.3, 8.5, 5.2, -1.1, 1.9);
                ctx.bezierCurveTo(7.4, 12.5, 7.5, 6.8, 12.9, 4.1);
                ctx.stroke();
            } else if (root.name === "snow") {
                for (let arm = 0; arm < 3; ++arm) {
                    const angle = arm * Math.PI / 3;
                    ctx.beginPath();
                    ctx.moveTo(8.5 - Math.cos(angle) * 5.7, 8.5 - Math.sin(angle) * 5.7);
                    ctx.lineTo(8.5 + Math.cos(angle) * 5.7, 8.5 + Math.sin(angle) * 5.7);
                    ctx.stroke();
                }
            } else if (root.name === "fog") {
                for (let line = 0; line < 3; ++line) {
                    ctx.beginPath();
                    ctx.moveTo(2.7, 5.2 + line * 3.3);
                    ctx.lineTo(14.3, 5.2 + line * 3.3);
                    ctx.stroke();
                }
            } else if (root.name === "storm") {
                ctx.beginPath();
                ctx.moveTo(9.5, 2.4);
                ctx.lineTo(5.8, 9.2);
                ctx.lineTo(9.1, 9.2);
                ctx.lineTo(7.5, 14.6);
                ctx.lineTo(12.1, 7.3);
                ctx.lineTo(8.8, 7.3);
                ctx.closePath();
                ctx.stroke();
            } else {
                ctx.beginPath();
                ctx.moveTo(4.3, 12.1);
                ctx.bezierCurveTo(2.6, 12.1, 2.0, 10.8, 2.0, 9.5);
                ctx.bezierCurveTo(2.0, 8.0, 3.2, 6.8, 4.7, 6.8);
                ctx.bezierCurveTo(5.4, 4.3, 8.4, 3.3, 10.6, 4.7);
                ctx.bezierCurveTo(12.3, 4.7, 13.4, 5.8, 13.6, 7.3);
                ctx.bezierCurveTo(15.1, 7.8, 15.5, 9.2, 14.8, 10.5);
                ctx.bezierCurveTo(14.2, 11.6, 13.2, 12.1, 11.8, 12.1);
                ctx.closePath();
                ctx.stroke();
                if (root.name === "rain") {
                    ctx.beginPath();
                    ctx.moveTo(6.3, 13.0);
                    ctx.lineTo(5.3, 15.0);
                    ctx.moveTo(10.8, 13.0);
                    ctx.lineTo(9.8, 15.0);
                    ctx.stroke();
                }
                if (root.name === "weatherUnavailable") {
                    ctx.beginPath();
                    ctx.moveTo(2.5, 14.5);
                    ctx.lineTo(14.5, 2.5);
                    ctx.stroke();
                }
            }
        } else if (root.name === "play" || root.name === "pause") {
            if (root.name === "play") {
                ctx.beginPath();
                ctx.moveTo(5.2, 3.2);
                ctx.lineTo(13.2, 8.5);
                ctx.lineTo(5.2, 13.8);
                ctx.closePath();
                ctx.fill();
            } else {
                ctx.fillRect(5.0, 3.4, 2.5, 10.2);
                ctx.fillRect(10.0, 3.4, 2.5, 10.2);
            }
        } else if (root.name === "effects") {
            const levels = [5.0, 8.5, 12.0];
            const knobs = [7.0, 11.0, 5.5];
            for (let index = 0; index < levels.length; ++index) {
                ctx.beginPath();
                ctx.moveTo(2.8, levels[index]);
                ctx.lineTo(14.2, levels[index]);
                ctx.stroke();
                ctx.beginPath();
                ctx.arc(knobs[index], levels[index], 1.45, 0, Math.PI * 2);
                ctx.fill();
            }
        } else if (root.name === "shuffle") {
            ctx.beginPath();
            ctx.moveTo(2.8, 4.7);
            ctx.lineTo(4.8, 4.7);
            ctx.bezierCurveTo(7.5, 4.7, 9.0, 12.3, 12.2, 12.3);
            ctx.lineTo(14.1, 12.3);
            ctx.moveTo(11.8, 10.4);
            ctx.lineTo(14.2, 12.3);
            ctx.lineTo(11.8, 14.2);
            ctx.moveTo(2.8, 12.3);
            ctx.lineTo(4.8, 12.3);
            ctx.bezierCurveTo(7.5, 12.3, 9.0, 4.7, 12.2, 4.7);
            ctx.lineTo(14.1, 4.7);
            ctx.moveTo(11.8, 2.8);
            ctx.lineTo(14.2, 4.7);
            ctx.lineTo(11.8, 6.6);
            ctx.stroke();
        } else if (root.name === "repeat") {
            ctx.beginPath();
            ctx.moveTo(3.0, 6.0);
            ctx.lineTo(12.0, 6.0);
            ctx.lineTo(10.0, 4.0);
            ctx.moveTo(12.0, 6.0);
            ctx.lineTo(10.0, 8.0);
            ctx.moveTo(14.0, 11.0);
            ctx.lineTo(5.0, 11.0);
            ctx.lineTo(7.0, 9.0);
            ctx.moveTo(5.0, 11.0);
            ctx.lineTo(7.0, 13.0);
            ctx.stroke();
        } else if (root.name === "undo" || root.name === "redo") {
            const reverse = root.name === "redo";
            const mirror = value => reverse ? 17 - value : value;
            ctx.beginPath();
            ctx.moveTo(mirror(3.2), 6.0);
            ctx.lineTo(mirror(6.0), 6.0);
            ctx.bezierCurveTo(mirror(11.2), 6.0, mirror(13.8), 7.0, mirror(13.8), 11.2);
            ctx.bezierCurveTo(mirror(13.8), 13.0, mirror(12.2), 14.0, mirror(10.0), 14.0);
            ctx.stroke();
            ctx.beginPath();
            ctx.moveTo(mirror(3.2), 6.0);
            ctx.lineTo(mirror(5.8), 3.8);
            ctx.moveTo(mirror(3.2), 6.0);
            ctx.lineTo(mirror(5.8), 8.2);
            ctx.stroke();
        } else if (root.name === "volumeHigh" || root.name === "volumeLow" || root.name === "volumeMuted") {
            ctx.beginPath();
            ctx.moveTo(2.4, 7.0);
            ctx.lineTo(5.2, 7.0);
            ctx.lineTo(8.4, 4.2);
            ctx.lineTo(8.4, 12.8);
            ctx.lineTo(5.2, 10.0);
            ctx.lineTo(2.4, 10.0);
            ctx.closePath();
            ctx.stroke();
            if (root.name === "volumeLow" || root.name === "volumeHigh") {
                ctx.beginPath();
                ctx.arc(8.7, 8.5, 3.0, -0.72, 0.72);
                ctx.stroke();
            }
            if (root.name === "volumeHigh") {
                ctx.beginPath();
                ctx.arc(8.7, 8.5, 5.4, -0.72, 0.72);
                ctx.stroke();
            }
            if (root.name === "volumeMuted") {
                ctx.beginPath();
                ctx.moveTo(11.0, 6.1);
                ctx.lineTo(15.0, 10.1);
                ctx.moveTo(15.0, 6.1);
                ctx.lineTo(11.0, 10.1);
                ctx.stroke();
            }
        } else if (root.name === "microphone" || root.name === "microphoneMuted") {
            ctx.beginPath();
            ctx.moveTo(8.5, 2.2);
            ctx.bezierCurveTo(6.9, 2.2, 6.0, 3.2, 6.0, 4.7);
            ctx.lineTo(6.0, 7.7);
            ctx.bezierCurveTo(6.0, 9.2, 6.9, 10.2, 8.5, 10.2);
            ctx.bezierCurveTo(10.1, 10.2, 11.0, 9.2, 11.0, 7.7);
            ctx.lineTo(11.0, 4.7);
            ctx.bezierCurveTo(11.0, 3.2, 10.1, 2.2, 8.5, 2.2);
            ctx.stroke();
            ctx.beginPath();
            ctx.arc(8.5, 8.0, 5.0, 0.08, Math.PI - 0.08);
            ctx.stroke();
            ctx.beginPath();
            ctx.moveTo(8.5, 13.0);
            ctx.lineTo(8.5, 15.0);
            ctx.moveTo(5.6, 15.0);
            ctx.lineTo(11.4, 15.0);
            ctx.stroke();
            if (root.name === "microphoneMuted") {
                ctx.strokeStyle = Theme.danger;
                ctx.beginPath();
                ctx.moveTo(3.0, 3.0);
                ctx.lineTo(14.0, 14.0);
                ctx.stroke();
            }
        }
    }
}
