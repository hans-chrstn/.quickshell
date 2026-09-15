import QtQuick
import Quickshell
import qs.services.wallpaper

ShellRoot {
    id: root
    property int stage: 0
    Component.onCompleted: {
        for (const screen of Quickshell.screens)
            WallpaperMonitorPowerService.acquire(screen.name);
    }
    Connections {
        target: WallpaperMonitorPowerService
        function onPoweredScreensChanged() {
            console.log("POWER_SERVICE", JSON.stringify(WallpaperMonitorPowerService.snapshot()));
        }
    }
    Timer {
        interval: 8000
        repeat: true
        running: true
        onTriggered: {
            ++root.stage;
            if (root.stage === 1) {
                for (const screen of Quickshell.screens)
                    WallpaperMonitorPowerService.release(screen.name);
            } else if (root.stage === 2) {
                for (const screen of Quickshell.screens)
                    WallpaperMonitorPowerService.acquire(screen.name);
            } else {
                Qt.quit();
            }
        }
    }
}
