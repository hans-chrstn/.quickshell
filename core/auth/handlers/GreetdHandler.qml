pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Greetd

Singleton {
    id: root
    signal ready()
    signal success()
    signal failed()

    property string user: ""
    property bool responseRequired: false

    Connections {
        target: Greetd
        
        function onAuthMessage(message, error, responseRequired, echoResponse) {
            root.responseRequired = responseRequired
            if (responseRequired) {
                root.ready()
            }
        }

        function onAuthFailure(message) {
            root.responseRequired = false
            root.failed()
        }

        function onReadyToLaunch() {
            root.responseRequired = false
            root.success()
        }
    }

    function start() {
        if (Greetd.available && root.user !== "") {
            root.responseRequired = false
            Greetd.createSession(root.user)
        }
    }

    function respond(password) {
        if (Greetd.available && root.responseRequired) {
            Greetd.respond(password)
        }
    }
}
