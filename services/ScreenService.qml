pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    function resolve(preferredName) {
        if (preferredName) {
            for (let screen of Quickshell.screens) {
                if (screen.name === preferredName)
                    return preferredName
            }
        }

        const focused = Hyprland.focusedMonitor?.name ?? ""
        if (focused)
            return focused
        return Quickshell.screens.length > 0 ? Quickshell.screens[0].name : ""
    }
}
