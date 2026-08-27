//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_WAYLAND_DISABLE_WINDOWDECORATION=1

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.panels
import qs.services.launcher
import qs.services.session
import qs.services.settings
import qs.services.wallpaper

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
        function settings(): void { SettingsService.toggle() }
        function settingsOpen(): void { SettingsService.open() }
        function settingsOpenCategory(category: string): bool {
            return SettingsService.openCategory(category)
        }
        function settingsClose(): void { SettingsService.close() }
        function wallpapersRescan(): void {
            WallpaperCatalogService.rescan()
        }
        function wallpapersScan(paths: string): void {
            WallpaperCatalogService.rescan(paths.length > 0
                ? paths.split("|") : [])
        }
        function wallpapersStatus(): string {
            return JSON.stringify({
                scanning: WallpaperCatalogService.scanning,
                count: WallpaperCatalogService.wallpapers.length,
                wallpapers: WallpaperCatalogService.wallpapers,
                warnings: WallpaperCatalogService.warnings,
                error: WallpaperCatalogService.error
            })
        }
        function wallpaperSetGlobal(path: string): bool {
            return WallpaperAssignmentService.setGlobal(path)
        }
        function wallpaperClearGlobal(): void {
            WallpaperAssignmentService.clearGlobal()
        }
        function wallpaperSetScreen(screen: string, path: string): bool {
            return WallpaperAssignmentService.setForScreen(screen, path)
        }
        function wallpaperClearScreen(screen: string): void {
            WallpaperAssignmentService.clearScreen(screen)
        }
        function wallpaperForScreen(screen: string): string {
            return WallpaperAssignmentService.wallpaperForScreen(screen)
        }
        function wallpaperAssignments(): string {
            return JSON.stringify(WallpaperAssignmentService.snapshot())
        }
        function wallpaperRenderStatus(): string {
            return JSON.stringify(WallpaperRenderService.snapshot())
        }
        function monitors(): string {
            const renderers = WallpaperRenderService.snapshot()
            const overrides = WallpaperAssignmentService.screenWallpapers
            return JSON.stringify(Quickshell.screens.map(screen => {
                const name = String(screen.name || "")
                return {
                    name: name,
                    width: screen.width,
                    height: screen.height,
                    scale: screen.devicePixelRatio,
                    wallpaper: WallpaperAssignmentService.wallpaperForScreen(name),
                    wallpaperOverride: Boolean(overrides[name]),
                    renderer: renderers[name] || {
                        path: "",
                        state: "unavailable",
                        error: "Renderer is not available"
                    }
                }
            }))
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
