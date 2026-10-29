import QtQuick

Item {
    id: root

    property bool running: false
    property color ringColor: "#ffffaf32"

    implicitWidth: 18
    implicitHeight: 18
    rotation: 0

    Canvas {
        anchors.fill: parent

        onPaint: {
            const context = getContext("2d");
            context.reset();
            context.strokeStyle = root.ringColor;
            context.lineWidth = 1.8;
            context.lineCap = "round";
            context.beginPath();
            context.arc(width / 2, height / 2, Math.min(width, height) / 2 - 2, -Math.PI * 0.35, Math.PI * 1.15);
            context.stroke();
        }
    }

    NumberAnimation on rotation {
        from: 0
        to: 360
        duration: 950
        loops: Animation.Infinite
        running: root.running && root.visible
    }
}
