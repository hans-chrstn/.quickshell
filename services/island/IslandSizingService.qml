pragma Singleton

import QtQuick
import Quickshell
import "../../core/JsonCopy.js" as JsonCopy

Singleton {
    id: root

    property var screens: ({})

    function report(screenName, record) {
        const name = String(screenName || "").trim()
        if (name.length === 0 || !record)
            return false

        const updated = JsonCopy.value(screens)
        updated[name] = JsonCopy.value(record)
        screens = updated
        return true
    }

    function remove(screenName) {
        const name = String(screenName || "").trim()
        if (name.length === 0 || screens[name] === undefined)
            return false

        const updated = ({})
        for (const key in screens) {
            if (key !== name)
                updated[key] = JsonCopy.value(screens[key])
        }
        screens = updated
        return true
    }

    function snapshot() {
        return JsonCopy.value(screens)
    }
}
