import QtQuick

Canvas {
    id: root

    property string iconKind: "diamond"
    property color glyphColor: "#f2f2f4"

    implicitWidth: 18
    implicitHeight: 18

    onIconKindChanged: requestPaint()
    onGlyphColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onPaint: {
        const context = getContext("2d");
        context.reset();
        const logicalSize = 18;
        const glyphScale = Math.max(0, Math.min(width, height) / logicalSize);
        context.translate((width - logicalSize * glyphScale) / 2, (height - logicalSize * glyphScale) / 2);
        context.scale(glyphScale, glyphScale);
        context.strokeStyle = glyphColor;
        context.fillStyle = glyphColor;
        context.lineWidth = 1.55;
        context.lineCap = "round";
        context.lineJoin = "round";

        if (iconKind === "plus") {
            context.beginPath();
            context.moveTo(9, 3.5);
            context.lineTo(9, 14.5);
            context.moveTo(3.5, 9);
            context.lineTo(14.5, 9);
            context.stroke();
            return;
        }

        if (iconKind === "more") {
            context.beginPath();
            context.arc(4.2, 9, 1.15, 0, Math.PI * 2);
            context.arc(9, 9, 1.15, 0, Math.PI * 2);
            context.arc(13.8, 9, 1.15, 0, Math.PI * 2);
            context.fill();
            return;
        }

        if (iconKind === "close") {
            context.beginPath();
            context.moveTo(4.5, 4.5);
            context.lineTo(13.5, 13.5);
            context.moveTo(13.5, 4.5);
            context.lineTo(4.5, 13.5);
            context.stroke();
            return;
        }

        if (iconKind === "search") {
            context.beginPath();
            context.arc(7.8, 7.8, 4.6, 0, Math.PI * 2);
            context.moveTo(11.2, 11.2);
            context.lineTo(15, 15);
            context.stroke();
            return;
        }

        if (iconKind === "edit") {
            context.beginPath();
            context.moveTo(4, 14);
            context.lineTo(5, 10.5);
            context.lineTo(11.7, 3.8);
            context.lineTo(14.2, 6.3);
            context.lineTo(7.5, 13);
            context.closePath();
            context.moveTo(10.6, 4.9);
            context.lineTo(13.1, 7.4);
            context.stroke();
            return;
        }

        if (iconKind === "check") {
            context.beginPath();
            context.moveTo(3.2, 9.4);
            context.lineTo(7.1, 13.1);
            context.lineTo(14.8, 4.8);
            context.stroke();
            return;
        }

        if (iconKind === "spark") {
            context.beginPath();
            context.moveTo(9, 2.6);
            context.lineTo(10.4, 7.6);
            context.lineTo(15.4, 9);
            context.lineTo(10.4, 10.4);
            context.lineTo(9, 15.4);
            context.lineTo(7.6, 10.4);
            context.lineTo(2.6, 9);
            context.lineTo(7.6, 7.6);
            context.closePath();
            context.stroke();
            return;
        }

        if (iconKind === "trash") {
            context.beginPath();
            context.moveTo(5.2, 5.8);
            context.lineTo(5.9, 14.6);
            context.lineTo(12.1, 14.6);
            context.lineTo(12.8, 5.8);
            context.moveTo(4.1, 5.3);
            context.lineTo(13.9, 5.3);
            context.moveTo(7, 3.3);
            context.lineTo(11, 3.3);
            context.stroke();
            return;
        }

        if (iconKind === "chevron") {
            context.beginPath();
            context.moveTo(6.8, 4.2);
            context.lineTo(11.4, 9);
            context.lineTo(6.8, 13.8);
            context.stroke();
            return;
        }

        context.beginPath();
        context.moveTo(9, 2.8);
        context.lineTo(15.2, 9);
        context.lineTo(9, 15.2);
        context.lineTo(2.8, 9);
        context.closePath();
        context.stroke();
    }
}
