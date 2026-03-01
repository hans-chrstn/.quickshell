pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core
import "./lock"

Scope {
    id: root

    LockLogic {
        id: logic
        lock: lock
    }

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
                logic.buffer = ""
                logic.message = ""
            }
        }
    }

    Component.onCompleted: {
        LockManager.register(root, lock, logic)
    }
}
