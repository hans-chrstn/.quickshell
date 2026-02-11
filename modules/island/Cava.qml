import QtQuick
import QtQuick.Controls

Canvas {
    id: canvas
    anchors.fill: parent
    opacity: 0.2
    
    property int barCount: 20
    property int spacing: 4
    property color barColor: "white"
    
    Timer {
        id: timer
        interval: 100
        running: canvas.visible
        repeat: true
        onTriggered: canvas.requestPaint()
    }

    onPaint: {
        var ctx = getContext("2d");
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        
        var barWidth = (canvas.width - (canvas.barCount - 1) * canvas.spacing) / canvas.barCount;
        var radius = 2;

        function roundRect(ctx, x, y, width, height, radius) {
            if (width < 2 * radius) radius = width / 2;
            if (height < 2 * radius) radius = height / 2;
            ctx.beginPath();
            ctx.moveTo(x + radius, y);
            ctx.arcTo(x + width, y,   x + width, y + height, radius);
            ctx.arcTo(x + width, y + height, x, y + height, radius);
            ctx.arcTo(x, y + height, x, y, radius);
            ctx.arcTo(x, y, x + width, y, radius);
            ctx.closePath();
            return ctx;
        }
        
        for (var i = 0; i < canvas.barCount; i++) {
            var barHeight = canvas.height * (0.2 + (0.6 * Math.random()));
            var x = i * (barWidth + canvas.spacing);
            var y = canvas.height - barHeight;
            
            ctx.fillStyle = canvas.barColor;
            roundRect(ctx, x, y, barWidth, barHeight, radius).fill();
        }
    }
}
