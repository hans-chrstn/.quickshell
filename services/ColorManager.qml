pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.services

Singleton {
    id: root

    property url sourceUrl: ""
    
    readonly property color extractedColor: colorQuantizer.colors.length > 0 
        ? colorQuantizer.colors[0] 
        : ThemeManager.accentColor
    
    property color accentColor: ThemeManager.accentColor
    
    ColorQuantizer {
        id: colorQuantizer
        source: root.sourceUrl
        depth: 1
        rescaleSize: 64
    }

    Behavior on accentColor { 
        enabled: ThemeManager.lockDynamicAccents
        ColorAnimation { 
            duration: 1000 
            easing.type: Easing.OutCubic 
        } 
    }

    onExtractedColorChanged: {
        if (ThemeManager.lockDynamicAccents) {
            accentColor = extractedColor
        } else {
            accentColor = ThemeManager.accentColor
        }
    }
    
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            let musicArtUrl = (MusicManager.activePlayer && MusicManager.activePlayer.trackArtUrl && MusicManager.activePlayer.playbackState === MprisPlaybackState.Playing) 
                ? MusicManager.activePlayer.trackArtUrl 
                : "";
            
            if (musicArtUrl !== "") {
                root.sourceUrl = musicArtUrl;
            } else {
                root.sourceUrl = (WallpaperManager.activeWallpaperPath.startsWith("/") ? "file://" : "") + WallpaperManager.activeWallpaperPath;
            }
        }
    }
}
