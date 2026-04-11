pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Greetd
import qs.core
import qs.core.auth.handlers

Singleton {
    id: root

    enum State {
        Inactive,
        Identification,
        Ready,
        Loading,
        Success,
        Failed,
        Finish
    }

    property int state: AuthManager.State.Inactive

    property string currentUser: ""

    property string userUuid: ""

    property string blumePrefix: "◈ BLUME_KRN //"

    property string sentinelPrefix: "◈ SENTINEL_SEC //"

    property bool isGreeter: true

    property string authMode: Quickshell.env.QS_AUTH_MODE || "greet"

    readonly property var currentHandler: handlers[root.authMode]

    function identify(username) {
        if (root.state !== AuthManager.State.Identification && root.state !== AuthManager.State.Inactive) {
            return
        }
        
        root.currentUser = username
        _updateUuid()
        TerminalManager.displayMessage(root.blumePrefix + " Handshake initiated for " + username)
        root.currentHandler.user = username
        root.currentHandler.start()
    }

    function authenticate(password) {
        if (root.state !== AuthManager.State.Ready) {
            return
        }
        
        root.state = AuthManager.State.Loading
        TerminalManager.displayMessage(root.sentinelPrefix + " VALIDATING_CIPHER // TARGET: " + root.userUuid)
        root.currentHandler.respond(password)
    }

    function cancelIdentification() {
        root.currentUser = ""
        root.userUuid = ""
        root.state = AuthManager.State.Identification
        TerminalManager.displayMessage(root.blumePrefix + " Handshake terminated. Awaiting identification.")
    }

    function _updateUuid() {
        let hash = 0
        for (let i = 0; i < root.currentUser.length; i++) {
            hash = ((hash << 5) - hash) + root.currentUser.charCodeAt(i)
            hash |= 0
        }
        
        let hex = Math.abs(hash).toString(16).toUpperCase().padStart(8, "0")
        root.userUuid = "0x" + hex
    }

    function updateHandler() {
        root.state = AuthManager.State.Identification
    }

    Connections {
        target: root.currentHandler

        function onReady() {
            root.state = AuthManager.State.Ready
        }

        function onSuccess() {
            root.state = AuthManager.State.Success
            TerminalManager.displayMessage(root.blumePrefix + " IDENTITY_VERIFIED // WELCOME BACK")
            successTimer.start()
        }

        function onFailed() {
            root.state = AuthManager.State.Failed
            TerminalManager.displayMessage(root.sentinelPrefix + " AUTH_FAILED // TRACE_ID: " + root.userUuid)
            failTimer.start()
        }
    }

    Timer {
        id: successTimer
        interval: 500
        repeat: true
        onTriggered: {
            if (TerminalManager.isProcessing) {
                return
            }
            
            root.state = AuthManager.State.Finish
            TerminalManager.stopWorker()
            successTimer.stop()
            
            if (root.isGreeter && root.authMode === "greet") {
                let cmdString = SessionManager.currentSessionExec
                let cmd = []
                if (cmdString !== "") {
                    cmd = cmdString.match(/[^\s"']+|"([^"]*)"|'([^']*)'/g).map(arg => {
                        if (arg.startsWith('"') || arg.startsWith("'")) {
                            return arg.slice(1, -1)
                        }
                        return arg
                    })
                }
                
                if (cmd.length === 0) {
                    cmd = ["niri-session"]
                }
                
                Greetd.launch(cmd, ["XDG_SESSION_TYPE=wayland"], false)
            } else if (root.authMode === "fake") {
                exitTimer.start()
            }
        }
    }

    Timer {
        id: failTimer
        interval: 2000
        repeat: false
        onTriggered: {
            root.state = AuthManager.State.Ready
        }
    }

    Connections {
        target: Greetd
        function onLaunched() {
            if (root.authMode === "greet") {
                exitTimer.start()
            }
        }
    }

    Timer {
        id: exitTimer
        interval: 100
        repeat: false
        onTriggered: {
            Qt.quit()
        }
    }

    onAuthModeChanged: {
        root.updateHandler()
    }

    Component.onCompleted: {
        root.updateHandler()
    }

    readonly property var handlers: ({
        "fake": FakeHandler,
        "lock": LockdHandler,
        "greet": GreetdHandler
    })
}
