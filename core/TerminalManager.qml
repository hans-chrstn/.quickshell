pragma Singleton
import QtQuick
import Quickshell
import qs.shared
import qs.core.auth

Singleton {
    id: root

    property var _queue: []

    property var logModel: ListModel { }

    property bool isPaused: true

    signal paused(string pauseMarker)

    Timer {
        id: worker

        repeat: true

        interval: 100

        onTriggered: {
            if (root.isPaused) {
                worker.stop()
                return
            }

            if (root._queue.length === 0) {
                worker.stop()
                return
            }

            let item = root._queue.shift()
            root._addToModel(item)

            if (item.pauseWithMarker) {
                worker.stop()
                root.paused(item.pauseWithMarker)
                return
            }

            let minDelay = 150
            let maxDelay = 400
            let delay = minDelay + (Math.random() * (maxDelay - minDelay))
            worker.interval = delay
        }
    }

    function _addToModel(item) {
        logModel.append({
            message: item.message,
            raw: item.raw,
            isHeader: item.raw.startsWith("---")
        })

        if (logModel.count > 50) {
            logModel.remove(0)
        }
    }

    function displayMessage(message, pauseWithMarker = "") {
        let processed = ""
        if (!message.startsWith("---")) {
            let timestamp = new Date().toLocaleTimeString(
                Qt.locale(), 
                "HH:mm:ss"
            )
            let hex = (Math.random() * 0xFFFF).toString(16).toUpperCase().padStart(4, "0")
            processed = "[" + timestamp + "] 0x" + hex + " // " + message
        } else {
            processed = message
        }
        
        let item = {
            message: processed,
            raw: message,
            pauseWithMarker: pauseWithMarker
        }

        root._queue.push(item)

        if (!worker.running && !root.isPaused) {
            worker.start()
        }
    }

    function unpause() {
        root.isPaused = false
        if (!worker.running) {
            worker.start()
        }
    }

    function clear() {
        logModel.clear()
        _queue = []
    }

    function stopWorker() {
        worker.stop()
        root.isPaused = true
    }

    Component.onCompleted: {
        root.displayMessage("SENTINEL_IDP_LINK_ESTABLISHED")
        root.displayMessage("SPOOFING_SSL_CHANNEL... [OK]")
        root.displayMessage("BYPASSING_WATCHDOG_ENCRYPTION")
        root.displayMessage("WL_OUTPUT_PTR: GRANTED <0x8D2A>")
        root.displayMessage("---AUTHENTICATION_UI_ACTIVE---")
    }
}
