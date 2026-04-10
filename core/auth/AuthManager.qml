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
        Identify,
        Ready,
        Loading,
        Failed,
        Success,
        Finish
    }

    property string authMode: "greet"
    property int state: AuthManager.State.Inactive
    property string currentUser: ""
    property string userUuid: "0x00000000"
    property var _handler: null
    
    readonly property bool isGreeter: {
        return root.authMode === "greet" || root.authMode === "fake"
    }

    readonly property string blumePrefix: "[BLUME_IDP]"
    readonly property string sentinelPrefix: "[SENTINEL]"

    onCurrentUserChanged: {
        if (root.currentUser === "") {
            root.userUuid = "0x00000000"
            return
        }

        let hash = 0
        for (let i = 0; i < root.currentUser.length; i++) {
            hash = ((hash << 5) - hash) + root.currentUser.charCodeAt(i)
            hash |= 0
        }
        
        let hex = Math.abs(hash).toString(16).toUpperCase().padStart(8, "0")
        root.userUuid = "0x" + hex
    }

    Process {
        id: userDiscovery
        command: ["whoami"]
        stdout: StdioCollector {
            onStreamFinished: {
                let resolved = text.trim()
                if (resolved !== "" && root.authMode === "lock") {
                    root.currentUser = resolved
                    root.updateHandler()
                }
            }
        }
    }

    Connections {
        target: root._handler
        ignoreUnknownSignals: true
        function onReady() { 
            root.onHandlerReady() 
        }
        function onSuccess() { 
            root.onHandlerSuccess() 
        }
        function onFailed() { 
            root.onHandlerFailed() 
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
        interval: 300
        repeat: false
        onTriggered: {
            Qt.quit()
        }
    }

    onAuthModeChanged: {
        root.updateHandler()
    }

    Component.onCompleted: {
        if (root.authMode === "lock") {
            userDiscovery.running = true
        }
        root.updateHandler()
    }

    function updateHandler() {
        root._handler = root.handlers[root.authMode] || FakeHandler
        
        if (root.authMode === "lock") {
            if (root.currentUser === "") {
                userDiscovery.running = true
                return
            }
            root._handler.user = root.currentUser
            root.state = AuthManager.State.Ready
        } else if (root.authMode === "greet") {
            root.currentUser = ""
            root._handler.user = ""
            root.state = AuthManager.State.Identify
        } else {
            root.currentUser = ""
            root._handler.user = ""
            root.state = AuthManager.State.Identify
            root._handler.start()
        }

        if (root._handler) {
            root._handler.start()
        }
    }

    function identify(username) {
        if (!username) {
            return
        }
        root.currentUser = username
        if (root._handler) {
            root._handler.user = username
            root._handler.start()
        }
        TerminalManager.displayMessage(root.blumePrefix + " Handshake initiated for " + username)
    }

    function onHandlerReady() {
        root.state = AuthManager.State.Ready
        TerminalManager.displayMessage(root.blumePrefix + " Session initialized // PID_LINK: " + root.userUuid)
    }

    function onHandlerSuccess() {
        root.state = AuthManager.State.Success
        TerminalManager.displayMessage(root.blumePrefix + " IDENTITY_VERIFIED // WELCOME BACK")
        successTimer.start()
    }

    function onHandlerFailed() {
        root.state = AuthManager.State.Failed
        TerminalManager.displayMessage(root.sentinelPrefix + " AUTH_FAILED // TRACE_ID: " + root.userUuid)
        failTimer.start()
    }

    Timer {
        id: successTimer
        interval: 1000
        repeat: false
        onTriggered: {
            root.state = AuthManager.State.Finish
            TerminalManager.stopWorker()
            
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
            if (root._handler) {
                root._handler.start()
            }
        }
    }

    function authenticate(password) {
        if (root.state !== AuthManager.State.Ready) {
            return
        }
        root.state = AuthManager.State.Loading
        TerminalManager.displayMessage(root.sentinelPrefix + " VALIDATING_CIPHER // TARGET: " + root.userUuid)
        if (root._handler) {
            root._handler.respond(password)
        }
    }

    function cancelIdentification() {
        root.currentUser = ""
        root.state = AuthManager.State.Identify
        if (root.authMode === "greet") {
            Greetd.cancelSession()
        }
        TerminalManager.displayMessage(root.blumePrefix + " Handshake terminated. Awaiting identification.")
    }

    readonly property var handlers: ({
        "fake": FakeHandler,
        "lock": LockdHandler,
        "greet": GreetdHandler
    })
}
