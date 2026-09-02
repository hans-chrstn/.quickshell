pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    property var paths: ({})
    readonly property bool active: Object.keys(paths).length > 0

    function pathForScreen(screenName) {
        return String(paths[String(screenName || "").trim()] || "")
    }

    function replace(nextPaths) {
        paths = Object.assign({}, nextPaths || ({}))
    }

    function clear() {
        if (Object.keys(paths).length > 0)
            paths = ({})
    }

    function snapshot() {
        return { active: active, paths: Object.assign({}, paths) }
    }
}
