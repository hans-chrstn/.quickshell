pragma Singleton

import QtQuick
import Quickshell
import "WallpaperHookDiagnostics.js" as Diagnostics

Singleton {
    function snapshot() {
        return Diagnostics.derive(
            WallpaperHookService.snapshot(),
            WallpaperHookExecutorService.snapshot(),
            WallpaperPlaylistApplicationService.snapshot())
    }
}
