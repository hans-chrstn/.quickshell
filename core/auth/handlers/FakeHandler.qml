pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    property string user: ""

    signal ready()
    signal success()
    signal failed()

    Timer {
        id: resolveTimer
        interval: 1500
        repeat: false
        property string lastPass: ""
        onTriggered: {
            if (lastPass === "pass") {
                root.success()
            } else {
                root.failed()
            }
        }
    }

    function start() {
        root.ready()
    }

    function respond(password) {
        resolveTimer.lastPass = password
        resolveTimer.start()
    }
}
