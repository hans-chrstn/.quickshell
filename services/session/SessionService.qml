pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.core

Singleton {
    id: root

    property bool opened: false
    property bool closing: false
    property string targetScreenName: ""
    property int selectedIndex: 0
    property int confirmingIndex: -1

    readonly property var actions: [
        { id: "logout", title: "Log Out", symbol: "↪",
          color: Design.textMuted, destructive: true },
        { id: "restart", title: "Restart", symbol: "↻",
          color: Design.yellow, destructive: true },
        { id: "poweroff", title: "Shut Down", symbol: "⏻",
          color: Design.red, destructive: true }
    ]

    function focusedScreenName() {
        const monitor = Hyprland.focusedMonitor
        if (monitor?.name)
            return monitor.name
        return Quickshell.screens.length > 0 ? Quickshell.screens[0].name : ""
    }

    function open() {
        closeTimer.stop()
        closing = false
        targetScreenName = focusedScreenName()
        selectedIndex = 0
        confirmingIndex = -1
        opened = true
    }

    function close() {
        if (!opened || closing)
            return
        opened = false
        closing = true
        confirmingIndex = -1
        closeTimer.restart()
    }

    function toggle() { opened ? close() : open() }

    function moveSelection(delta) {
        selectedIndex = Math.max(0, Math.min(actions.length - 1,
                                             selectedIndex + delta))
        confirmingIndex = -1
    }

    function choose(index) {
        if (index < 0 || index >= actions.length)
            return
        selectedIndex = index
        const action = actions[index]
        if (action.destructive && confirmingIndex !== index) {
            confirmingIndex = index
            return
        }

        close()
        actionDelay.actionId = action.id
        actionDelay.restart()
    }

    function execute(actionId) {
        if (actionId === "logout")
            Hyprland.dispatch(Hyprland.usingLua ? "hl.dsp.exit()" : "exit")
        else if (actionId === "restart")
            Quickshell.execDetached(["systemctl", "reboot"])
        else if (actionId === "poweroff")
            Quickshell.execDetached(["systemctl", "poweroff"])
    }

    Timer {
        id: actionDelay
        property string actionId: ""
        interval: 180
        onTriggered: root.execute(actionId)
    }

    Timer {
        id: closeTimer
        interval: Design.moduleCloseDuration
        onTriggered: root.closing = false
    }
}
