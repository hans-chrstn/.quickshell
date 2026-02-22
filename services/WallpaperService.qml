pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

Singleton {
    id: root
    property string activeWallpaper: ""
    property string previewWallpaper: ""
    property string lastWallpaper: ""
    
    property string transitionType: "grow"
    property real transitionDuration: 1.5
    property int slideshowInterval: 300000
    
    readonly property string cachePath: Quickshell.cachePath("current_wallpaper")
    readonly property string settingsPath: Quickshell.cachePath("wallpaper_settings.json")

    function saveSettings(): void {
        let data = {
            "transitionType": root.transitionType,
            "transitionDuration": root.transitionDuration,
            "slideshowInterval": root.slideshowInterval
        }
        settingsFile.setText(JSON.stringify(data))
    }

    FileView {
        id: settingsFile
        path: root.settingsPath
        onLoaded: {
            try {
                let data = JSON.parse(text())
                if (data.transitionType !== undefined) root.transitionType = data.transitionType
                if (data.transitionDuration !== undefined) root.transitionDuration = data.transitionDuration
                if (data.slideshowInterval !== undefined) root.slideshowInterval = data.slideshowInterval
            } catch (e) {}
        }
    }

    onTransitionTypeChanged: saveSettings()
    onTransitionDurationChanged: saveSettings()
    onSlideshowIntervalChanged: saveSettings()

    FileView {
        id: currentWallFile
        path: root.cachePath
        onLoaded: {
            let p = text().trim()
            if (p !== "") {
                root.activeWallpaper = p
                root.previewWallpaper = p
            }
        }
    }

    function apply(): void {
        if (previewWallpaper === "") return
        stopSlideshow()
        lastWallpaper = activeWallpaper
        activeWallpaper = previewWallpaper
        
        currentWallFile.setText(activeWallpaper)
        Quickshell.execDetached([
            "swww", "img", previewWallpaper, 
            "--transition-type", root.transitionType, 
            "--transition-pos", "center", 
            "--transition-duration", root.transitionDuration.toString()
        ])
    }

    property string slideshowDir: ""
    property bool isSlideshowActive: slideshowTimer.running
    
    Timer {
        id: slideshowTimer
        interval: root.slideshowInterval
        repeat: true
        onTriggered: pickRandomFromFolder()
    }

    function startSlideshow(dir: string): void {
        slideshowDir = dir
        pickRandomFromFolder()
        slideshowTimer.start()
    }

    function stopSlideshow(): void {
        slideshowTimer.stop()
    }

    Process {
        id: shufProc
        stdout: StdioCollector {
            onStreamFinished: {
                let path = text.trim()
                if (path !== "") {
                    activeWallpaper = path
                    currentWallFile.setText(activeWallpaper)
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

    function pickRandomFromFolder(): void {
        if (slideshowDir === "") return
        shufProc.running = false
        shufProc.command = ["sh", "-c", `find "${slideshowDir}" -maxdepth 1 -type f -iregex '.*\\.\(jpg\\|jpeg\\|png\\|webp\\)' | shuf -n 1`]
        Qt.callLater(() => { shufProc.running = true })
    }

    function revert(): void {
        if (lastWallpaper === "") return
        previewWallpaper = lastWallpaper
        apply()
    }

    Component.onCompleted: {
        Quickshell.execDetached(["swww-daemon"])
        FileBrowserService.currentPath = Quickshell.env("HOME") + "/Pictures"
    }
}
