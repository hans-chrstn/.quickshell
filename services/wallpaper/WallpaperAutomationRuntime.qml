import QtQuick
import qs.services.wallpaper

Item {
    readonly property bool applicationActive:
        WallpaperPlaylistApplicationService.active

    Component.onCompleted: WallpaperPlaylistSchedulerService.initialize()
}
