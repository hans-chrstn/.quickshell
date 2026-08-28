pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core.auth

Singleton {
    id: root
    property var lockModule: null
    property var lockObject: null
    property var pamObject: null
    readonly property bool isLocked: {
        return lockObject ? !!lockObject.locked : false
    }
    
    function register(module, lock, pam) {
        root.lockModule = module
        root.lockObject = lock
        root.pamObject = pam
    }

    function lock() {
        if (lockObject) {
            AuthManager.authMode = "lock"
            AuthManager.updateHandler()
            lockObject.locked = true
        }
    }

    function unlock() {
        if (lockObject) {
            lockObject.locked = false
        }
    }
}
