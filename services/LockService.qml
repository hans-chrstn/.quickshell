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
    readonly property bool isGreeter: Greetd.available
    
    readonly property string buffer: pamObject ? pamObject.buffer : ""
    readonly property string message: pamObject ? pamObject.message : ""
    readonly property bool messageIsError: pamObject ? pamObject.messageIsError : false

    function registerLock(module, lock, pam) {
        root.lockModule = module
        root.lockObject = lock
        root.pamObject = pam
    }

    function handleKey(event) {
        if (pamObject) pamObject.handleKey(event)
    }

    function lockSession() {
        if (lockObject) {
            lockObject.locked = true
        }
    }

    function unlock() {
        if (lockObject) {
            lockObject.unlock()
        }
    }

    readonly property var pamContext: pamObject ? pamObject.passwd : null
}
