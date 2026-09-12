import QtQuick

QtObject {
    id: root

    property real progress: 1
    property bool running: false
    property int generation: 0
    property int durationMs: 0

    signal completed(int generation)

    function start(nextGeneration, nextDurationMs) {
        progressAnimation.stop()
        generation = nextGeneration
        durationMs = Math.max(0, Math.round(Number(nextDurationMs) || 0))
        progress = durationMs > 0 ? 0 : 1
        running = durationMs > 0
        if (running)
            progressAnimation.start()
        else
            completed(generation)
    }

    function cancel() {
        progressAnimation.stop()
        running = false
        progress = 1
    }

    property NumberAnimation progressAnimation: NumberAnimation {
        target: root
        property: "progress"
        from: 0
        to: 1
        duration: root.durationMs
        easing.type: Easing.InOutCubic
        onFinished: {
            root.progress = 1
            root.running = false
            root.completed(root.generation)
        }
    }
}
