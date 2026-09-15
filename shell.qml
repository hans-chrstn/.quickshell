//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_WAYLAND_DISABLE_WINDOWDECORATION=1

import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.components.lifecycle
import qs.panels
import qs.services.ipc
import qs.services.config
import qs.services.display
import qs.services.launcher
import qs.services.notifications
import qs.services.session
import qs.services.wallpaper
import qs.services.wallpaper.projects

ShellRoot {
    // Instantiate the opt-in controller once at the root. It remains inert
    // while disabled and owns no polling or display state itself.
    readonly property var displayPowerControl: DisplayPowerControlService

    ShellIpc {}

    NotificationDaemon {}

    WallpaperAutomationActivator {}

    LifecycleLoader {
        resourceId: "wallpaper.cache-coordinator"
        owner: "shell"
        restorationSource: "ConfigService and dedicated cache directories"
        classification: "active-only"
        requestedActive: ConfigService.automaticWallpaperCacheCleanup
        retentionReason: requestedActive ? "automatic-cleanup-enabled" : ""
        evictionReason: requestedActive ? "" : "automatic-cleanup-disabled"
        sourceComponent: Component {
            WallpaperCacheCoordinator {}
        }
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

        delegate: WallpaperWindow {
            required property var modelData
            screen: modelData
        }
    }

    Variants {
        model: Quickshell.screens

        delegate: IslandWindow {
            required property var modelData
            screen: modelData
        }
    }
}
