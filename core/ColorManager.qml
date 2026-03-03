pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.core

Singleton {
    id: root

    property url sourceUrl: ""
    
    readonly property color extractedColor: colorQuantizer.colors.length > 0 
        ? colorQuantizer.colors[0] 
        : ThemeManager.manualAccentColor
    
    property color accentColor: ThemeManager.manualAccentColor
    
    ColorQuantizer {
        id: colorQuantizer
        source: root.sourceUrl
        depth: 1
        rescaleSize: 64
    }

    onExtractedColorChanged: {
        root.accentColor = extractedColor
    }

    Behavior on accentColor {
        ColorAnimation {
            duration: 1000
            easing.type: Easing.OutCubic
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            let musicArtUrl = (MusicManager.activePlayer && MusicManager.activePlayer.trackArtUrl && MusicManager.activePlayer.playbackState === MprisPlaybackState.Playing) 
                ? MusicManager.activePlayer.trackArtUrl 
                : "";
            
            let isRemote = musicArtUrl.toString().startsWith("http");
            
            if (musicArtUrl !== "" && !isRemote) {
                root.sourceUrl = musicArtUrl;
            } else {
                let wpPath = WallpaperManager.activeWallpaperPath;
                if (wpPath) {
                    let uri = wpPath.startsWith("/") ? "file://" + wpPath : wpPath;
                    root.sourceUrl = uri;
                } else {
                    root.sourceUrl = "";
                }
            }
        }
    }
}
