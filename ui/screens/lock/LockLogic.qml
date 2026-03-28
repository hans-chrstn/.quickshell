import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import Quickshell.Services.Greetd
import qs.core

QtObject {
    id: root

    property string buffer: ""
    property string message: ""
    property bool messageIsError: false
    property var lock

    function handleKey(event) {
        if (!lock || !lock.locked) {
            return
        }

        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (Greetd.available) {
                Greetd.respond(buffer)
                buffer = ""
            } else {
                if (!passwd.isActive) {
                    passwd.start()
                } else if (passwd.isResponseRequired) {
                    passwd.respond(buffer)
                    buffer = ""
                }
            }
        } else if (event.key === Qt.Key_Backspace) {
            if (event.modifiers & Qt.ControlModifier) {
                buffer = ""
            } else {
                buffer = buffer.slice(0, -1)
            }
        } else if (event.text.length === 1 && event.text !== "\r" && event.text !== "\n") {
            buffer += event.text
        }
    }

    property var passwd: PamContext {
        id: passwd
        config: "login"

        onMessageChanged: {
            if (message && message !== "Password: ") {
                root.message = message
                root.messageIsError = messageIsError
            }
        }

        onResponseRequiredChanged: {
            if (responseRequired && root.buffer.length > 0) {
                respond(root.buffer)
                root.buffer = ""
            }
        }

        onCompleted: (result) => {
            if (result === PamResult.Success) {
                SoundManager.playSuccess()
                if (lock) lock.requestDismiss()
            } else {
                root.buffer = ""
                if (!root.message || root.message === "Password: ") {
                    root.message = "Authentication failed"
                    root.messageIsError = true
                }
            }
        }
    }
}
