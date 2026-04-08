pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core
import qs.ui.screens.lock

Scope {
    id: root

    WlSessionLock {
        id: lock

        surface: Component {
            LockSurface {
                lock: lock
            }
        }
    }

    Component.onCompleted: {
        LockManager.register(root, lock, null)
    }
}
