pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.services

Singleton {
    id: root

    property url source: ""
    
    readonly property color sourceColor: quantizer.colors.length > 0 ? quantizer.colors[0] : ThemeService.accentColor
    
    property color accent: ThemeService.accentColor
    
    ColorQuantizer {
        id: quantizer
        source: root.source
        depth: 1
        rescaleSize: 64
    }

    Behavior on accent { 
        enabled: ThemeService.lockDynamicAccents
        ColorAnimation { duration: 1000; easing.type: Easing.OutCubic } 
    }

    onSourceColorChanged: {
        if (ThemeService.lockDynamicAccents) {
            accent = sourceColor
        } else {
            accent = ThemeService.accentColor
        }
    }
    
    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: {
            let musicSource = (MusicService.activePlayer && MusicService.activePlayer.trackArtUrl && MusicService.activePlayer.playbackState === MprisPlaybackState.Playing) 
                ? MusicService.activePlayer.trackArtUrl : "";
            
            if (musicSource !== "") {
                root.source = musicSource;
            } else {
                root.source = (WallpaperService.activeWallpaper.startsWith("/") ? "file://" : "") + WallpaperService.activeWallpaper;
            }
        }
    }
}
