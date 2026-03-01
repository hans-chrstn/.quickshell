import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Greetd
import qs.core

QtObject {
    id: root

    property bool isAuthenticated: false
    property bool isUserSelected: Greetd.user !== ""
    property string usernameBuffer: ""
    property string passwordBuffer: ""
    property string statusMessage: "Enter Username"
    property bool isErrorMessage: false
    property bool showSessionPicker: false

    readonly property string lastUserCachePath: Quickshell.cachePath("last_user")

    function handleKey(event) {
        if (showSessionPicker) return

        if (event.key === Qt.Key_C && (event.modifiers & Qt.ControlModifier)) {
            event.accepted = true
            return
        }

        if (event.key === Qt.Key_Backspace) {
            SoundManager.playClick()
            if (event.modifiers & Qt.ControlModifier) {
                if (!isUserSelected) {
                    usernameBuffer = ""
                } else {
                    passwordBuffer = ""
                }
            } else {
                if (!isUserSelected) {
                    if (usernameBuffer.length > 0) {
                        usernameBuffer = usernameBuffer.slice(0, -1)
                    }
                } else {
                    if (passwordBuffer.length > 0) {
                        passwordBuffer = passwordBuffer.slice(0, -1)
                    }
                }
            }
            event.accepted = true
            return
        }

        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (!isUserSelected) {
                if (usernameBuffer.length > 0) {
                    statusMessage = "Authenticating..."
                    isErrorMessage = false
                    Greetd.createSession(usernameBuffer)
                }
            } else {
                if (Greetd.state === GreetdState.Authenticating) {
                    statusMessage = "Verifying..."
                    isErrorMessage = false
                    Greetd.respond(passwordBuffer)
                    passwordBuffer = ""
                } else if (Greetd.state === GreetdState.Inactive) {
                    statusMessage = "Authenticating..."
                    isErrorMessage = false
                    Greetd.createSession(Greetd.user)
                } else if (Greetd.state === GreetdState.ReadyToLaunch) {
                    statusMessage = "Launching Session..."
                    launchTimer.start()
                }
            }
            event.accepted = true
            return
        }

        if (event.key === Qt.Key_Escape) {
            if (isUserSelected) {
                Greetd.cancelSession()
                Greetd.createSession("")
                passwordBuffer = ""
                usernameBuffer = ""
                statusMessage = "Enter Username"
                isErrorMessage = false
                SoundManager.playOff()
            }
            event.accepted = true
            return
        }

        if (event.text.length === 1 && event.text !== "" && event.text !== "
") {
            SoundManager.playClick()
            if (!isUserSelected) {
                usernameBuffer += event.text
            } else {
                passwordBuffer += event.text
            }
            event.accepted = true
        }
    }

    property var lastUserFile: FileView {
        path: root.lastUserCachePath
        onLoaded: {
            let lastUser = text().trim()
            if (lastUser && !root.isUserSelected) {
                root.usernameBuffer = lastUser
            }
        }
    }

    property var connections: Connections {
        target: Greetd
        function onAuthMessage(message, isError, responseRequired, echoResponse) {
            if (message) {
                if (message.toLowerCase().includes("password")) {
                    root.statusMessage = "Enter Password"
                } else {
                    root.statusMessage = message
                }
                root.isErrorMessage = isError
            }
        }

        function onAuthFailure(message) {
            root.passwordBuffer = ""
            root.statusMessage = message || "Authentication failed"
            root.isErrorMessage = true
            SoundManager.playCollapse()
        }

        function onReadyToLaunch() {
            root.isAuthenticated = true
            SoundManager.playSuccess()
            root.lastUserFile.setText(Greetd.user)
            launchTimer.start()
        }

        function onError(error) {
            root.statusMessage = error
            root.isErrorMessage = true
        }
    }

    property var launchTimer: Timer {
        interval: 1000
        onTriggered: {
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

            Greetd.launch(cmd, ["XDG_SESSION_TYPE=wayland"])
        }
    }
}
