//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_WAYLAND_DISABLE_WINDOWDECORATION=1

import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.components.lifecycle
import qs.editor
import qs.panels
import qs.services.ipc
import qs.services.config
import qs.services.launcher
import qs.services.notifications
import qs.services.session
import qs.services.wallpaper
import qs.services.wallpaper.projects

ShellRoot {
    ShellIpc {}

    NotificationDaemon {}

    WallpaperAutomationActivator {}

    LifecycleLoader {
        resourceId: "wallpaper.editor-window"
        owner: "shell"
        restorationSource: "WallpaperEditorService and WallpaperProjectService"
        classification: "active-only"
        requestedActive: WallpaperEditorService.opened
            || WallpaperEditorService.closing
        usageActive: WallpaperEditorService.opened
        retentionReason: requestedActive ? "editor-visible-or-closing" : ""
        evictionReason: requestedActive ? "" : "editor-closed"
        source: Qt.resolvedUrl("editor/WallpaperEditorWindow.qml")
    }

    LifecycleLoader {
        resourceId: "wallpaper.cache-coordinator"
        owner: "shell"
        restorationSource: "ConfigService and dedicated cache directories"
        classification: "active-only"
        requestedActive: ConfigService.automaticWallpaperCacheCleanup
        retentionReason: requestedActive ? "automatic-cleanup-enabled" : ""
        evictionReason: requestedActive ? "" : "automatic-cleanup-disabled"
        sourceComponent: Component { WallpaperCacheCoordinator {} }
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
