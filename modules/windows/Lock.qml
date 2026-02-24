pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import Quickshell.Services.Greetd
import qs.services

Scope {
    id: root

    WlSessionLock {
        id: lock

        signal unlock

        surface: Component {
            LockSurface {
                lock: lock
            }
        }
        
        onLockedChanged: {
            if (locked) {
                pam.buffer = ""
                pam.message = ""
            }
        }
    }

    QtObject {
        id: pam

        property string buffer: ""
        property string message: ""
        property bool messageIsError: false

        function handleKey(event) {
            if (!lock.locked) return;
            
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

        property PamContext passwd: PamContext {
            id: passwd
            config: "login"
            
            onMessageChanged: {
                if (message && message !== "Password: ") {
                    pam.message = message
                    pam.messageIsError = messageIsError
                }
            }
            
            onResponseRequiredChanged: {
                if (responseRequired && pam.buffer.length > 0) {
                    respond(pam.buffer)
                    pam.buffer = ""
                }
            }
            
            onCompleted: (result) => {
                if (result === PamResult.Success) {
                    lock.unlock()
                } else {
                    pam.buffer = ""
                    if (!pam.message || pam.message === "Password: ") {
                        pam.message = "Authentication failed"
                        pam.messageIsError = true
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        LockService.registerLock(root, lock, pam)
    }
}
