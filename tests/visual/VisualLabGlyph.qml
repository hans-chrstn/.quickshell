import QtQuick

Canvas {
    id: root

    property color glyphColor: "#f5f5f7"

    implicitWidth: 19
    implicitHeight: 19

    onGlyphColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onPaint: {
        const context = getContext("2d");
        context.reset();
        const logicalSize = 19;
        const glyphScale = Math.max(0, Math.min(width, height) / logicalSize);
        context.translate((width - logicalSize * glyphScale) / 2, (height - logicalSize * glyphScale) / 2);
        context.scale(glyphScale, glyphScale);
        context.strokeStyle = glyphColor;
        context.lineWidth = 1.6;
        context.lineCap = "round";
        context.lineJoin = "round";
        context.beginPath();
        context.moveTo(9.5, 2.7);
        context.lineTo(16.3, 9.5);
        context.lineTo(9.5, 16.3);
        context.lineTo(2.7, 9.5);
        context.closePath();
        context.stroke();
        context.beginPath();
        context.arc(9.5, 9.5, 2.8, 0, Math.PI * 2);
        context.stroke();
    }
}
