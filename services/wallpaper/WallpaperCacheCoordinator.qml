import QtQuick
import qs.services.wallpaper

Item {
    id: root
    visible: false
    width: 0
    height: 0

    Component.onCompleted: startupTimer.start()

    function schedule() {
        cleanupTimer.restart()
    }

    Connections {
        target: WallpaperPosterService
        function onRecordsChanged() { root.schedule() }
    }

    Connections {
        target: WallpaperOptimizationService
        function onRecordsChanged() { root.schedule() }
    }

    property Timer startupTimer: Timer {
        interval: 5000
        onTriggered: WallpaperCacheService.requestAutomaticCleanup()
    }

    property Timer cleanupTimer: Timer {
        interval: 1500
        onTriggered: WallpaperCacheService.requestAutomaticCleanup()
    }
}
