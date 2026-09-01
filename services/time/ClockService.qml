pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    property var consumers: ({})
    property date now: new Date()
    readonly property int consumerCount: Object.keys(consumers).length
    readonly property bool active: consumerCount > 0

    function setConsumer(resourceId, requested) {
        const id = String(resourceId || "").trim().slice(0, 192)
        if (id.length === 0)
            return false
        const enabled = Boolean(requested)
        if (Boolean(consumers[id]) === enabled)
            return true
        const updated = Object.assign({}, consumers)
        if (enabled)
            updated[id] = true
        else
            delete updated[id]
        const activating = Object.keys(consumers).length === 0
            && Object.keys(updated).length > 0
        consumers = updated
        if (activating)
            now = new Date()
        return true
    }

    function snapshot() {
        return {
            active: active,
            consumerCount: consumerCount,
            consumers: Object.keys(consumers).sort(),
            precision: "minute",
            now: now.toISOString()
        }
    }

    SystemClock {
        id: systemClock
        enabled: root.active
        precision: SystemClock.Minutes
        onDateChanged: root.now = date
    }
}
