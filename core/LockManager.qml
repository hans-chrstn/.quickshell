pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import Quickshell.Services.Greetd

Singleton {
    id: root

    property var lockModule: null
    property var lockObject: null
    property var pamObject: null

    readonly property bool isLocked: lockObject ? !!lockObject.locked : false
    readonly property bool isGreeterAvailable: Greetd.available
    
    readonly property string passwordBuffer: pamObject ? pamObject.buffer : ""
    readonly property string statusMessage: pamObject ? pamObject.message : ""
    readonly property bool isErrorMessage: pamObject ? pamObject.messageIsError : false

    function register(module, lock, pam) {
        root.lockModule = module
        root.lockObject = lock
        root.pamObject = pam
    }

    function processKeyEvent(event) {
        if (pamObject) {
            pamObject.handleKey(event)
        }
    }

    function lock() {
        if (lockObject) {
            lockObject.locked = true
        }
    }

    function unlock() {
        if (lockObject) {
            lockObject.unlock()
        }
    }

    readonly property var authenticationContext: pamObject ? pamObject.passwd : null
}
