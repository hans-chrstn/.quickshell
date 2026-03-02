pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.core

Singleton {
    id: root
    
    property string activeWallpaperPath: ""
    property string previewWallpaperPath: ""
    property string previousWallpaperPath: ""
    
    property string transitionType: "grow"
    property real transitionDuration: 1.5
    property int slideshowInterval: 300000
    
    readonly property string wallpaperCachePath: Quickshell.cachePath("current_wallpaper")
    readonly property string wallpaperSettingsPath: Quickshell.cachePath("wallpaper_settings.json")

    function saveSettings() {
        let settingsData = {
            "transitionType": root.transitionType,
            "transitionDuration": root.transitionDuration,
            "slideshowInterval": root.slideshowInterval
        }
        settingsFile.setText(JSON.stringify(settingsData))
    }

    FileView {
        id: settingsFile
        path: root.wallpaperSettingsPath
        onLoaded: {
            try {
                let settingsData = JSON.parse(text())
                if (settingsData.transitionType !== undefined) root.transitionType = settingsData.transitionType
                if (settingsData.transitionDuration !== undefined) root.transitionDuration = settingsData.transitionDuration
                if (settingsData.slideshowInterval !== undefined) root.slideshowInterval = settingsData.slideshowInterval
            } catch (error) {}
        }
    }

    onTransitionTypeChanged: saveSettings()
    onTransitionDurationChanged: saveSettings()
    onSlideshowIntervalChanged: saveSettings()

    FileView {
        id: currentWallpaperFile
        path: root.wallpaperCachePath
        onLoaded: {
            let path = text().trim()
            if (path !== "") {
                root.activeWallpaperPath = path
                root.previewWallpaperPath = path
            }
        }
    }

    function applyWallpaper() {
        if (previewWallpaperPath === "") return
        stopSlideshow()
        previousWallpaperPath = activeWallpaperPath
        activeWallpaperPath = previewWallpaperPath
        
        currentWallpaperFile.setText(activeWallpaperPath)
        Quickshell.execDetached([
            "swww", "img", previewWallpaperPath, 
            "--transition-type", root.transitionType, 
            "--transition-pos", "center", 
            "--transition-duration", root.transitionDuration.toString()
        ])
    }

    property string currentSlideshowDirectory: ""
    readonly property bool isSlideshowRunning: slideshowTimer.running
    
    Timer {
        id: slideshowTimer
        interval: root.slideshowInterval
        repeat: true
        onTriggered: pickRandomWallpaperFromFolder()
    }

    function startSlideshow(directory) {
        currentSlideshowDirectory = directory
        pickRandomWallpaperFromFolder()
        slideshowTimer.start()
    }

    function stopSlideshow() {
        slideshowTimer.stop()
    }

    Process {
        id: shuffleProcess
        stdout: StdioCollector {
            onStreamFinished: {
                let path = text.trim()
                if (path !== "") {
                    activeWallpaperPath = path
                    currentWallpaperFile.setText(activeWallpaperPath)
                    Quickshell.execDetached([
                        "swww", "img", path, 
                        "--transition-type", root.transitionType, 
                        "--transition-pos", "center", 
                        "--transition-duration", root.transitionDuration.toString()
                    ])
                }
            }
        }
    }

    function pickRandomWallpaperFromFolder() {
        if (currentSlideshowDirectory === "") return
        shuffleProcess.running = false
        shuffleProcess.command = ["sh", "-c", `find "${currentSlideshowDirectory}" -maxdepth 1 -type f -iregex '.*\.\(jpg\|jpeg\|png\|webp\)' | shuf -n 1`]
        Qt.callLater(() => { shuffleProcess.running = true })
    }

    function revertWallpaper() {
        if (previousWallpaperPath === "") return
        previewWallpaperPath = previousWallpaperPath
        applyWallpaper()
    }

    Component.onCompleted: {
        Quickshell.execDetached(["swww-daemon"])
    }
}
