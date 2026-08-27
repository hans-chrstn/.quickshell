//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_WAYLAND_DISABLE_WINDOWDECORATION=1

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.panels
import qs.services.launcher
import qs.services.session

ShellRoot {
    IpcHandler {
        target: "new-shell"

        function launcher(): void { LauncherService.toggle() }
        function launcherOpen(query: string): void {
            LauncherService.open(query)
        }
        function launcherClose(): void { LauncherService.close() }
        function session(): void { SessionService.toggle() }
        function sessionOpen(): void { SessionService.open() }
        function sessionClose(): void { SessionService.close() }
    }

    GlobalShortcut {
        appid: "new-shell"
        name: "launcher"
        description: "Open the application launcher"
        onPressed: LauncherService.toggle()
    }

    GlobalShortcut {
        appid: "new-shell"
        name: "session"
        description: "Open the session and power menu"
        onPressed: SessionService.toggle()
    }

    Variants {
        model: Quickshell.screens

        delegate: IslandWindow {
            required property var modelData
            screen: modelData
        }
    }
}
