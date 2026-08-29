pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    property var screens: ({})

    function report(screenName, path, state, error, kind) {
        const name = String(screenName || "").trim()
        if (name.length === 0)
            return

        const updated = ({})
        for (const key in screens)
            updated[key] = screens[key]
        updated[name] = {
            path: String(path || ""),
            kind: String(kind || "unknown"),
            state: String(state || "empty"),
            error: String(error || "")
        }
        screens = updated
    }

    function remove(screenName) {
        const name = String(screenName || "").trim()
        const updated = ({})
        for (const key in screens) {
            if (key !== name)
                updated[key] = screens[key]
        }
        screens = updated
    }

    function snapshot() {
        return screens
    }
}
