pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Greetd

Singleton {
    id: root
    signal ready()
    signal success()
    signal failed()

    Connections {
        target: Greetd
        
        function onAuthMessage(message, error, responseRequired, echoResponse) {
            if (responseRequired) {
                root.ready()
            }
        }

        function onAuthFailure(message) {
            root.failed()
        }

        function onReadyToLaunch() {
            root.success()
        }
    }

    function start() {
        if (Greetd.available) {
            Greetd.createSession(AuthManager.currentUser)
        }
    }

    function respond(password) {
        if (Greetd.available) {
            Greetd.respond(password)
        }
    }
}
