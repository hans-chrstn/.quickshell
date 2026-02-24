import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Services.Mpris
import qs.services

Item {
    id: root
    anchors.fill: parent

    property real mouseX: 0
    property real mouseY: 0

    Item {
        id: bgContainer
        anchors.fill: parent
        
        Item {
            anchors.fill: parent
            scale: 1.05
            transform: Translate {
                x: root.mouseX * -ThemeService.lockParallaxIntensity
                y: root.mouseY * -ThemeService.lockParallaxIntensity
                Behavior on x { NumberAnimation { duration: 1000; easing.type: Easing.OutCubic } }
                Behavior on y { NumberAnimation { duration: 1000; easing.type: Easing.OutCubic } }
            }

            Image {
                id: wallpaper
                anchors.fill: parent
                source: (WallpaperService.activeWallpaper.startsWith("/") ? "file://" : "") + WallpaperService.activeWallpaper
                fillMode: Image.PreserveAspectCrop
                visible: WallpaperService.activeWallpaper !== ""
                
                layer.enabled: true
                layer.effect: MultiEffect {
                    blurEnabled: true
                    blur: ThemeService.lockBackgroundBlur
                    blurMax: 64
                }
            }

            Image {
                id: trackArtBg
                anchors.fill: parent
                source: MusicService.activePlayer ? MusicService.activePlayer.trackArtUrl : ""
                fillMode: Image.PreserveAspectCrop
                opacity: (MusicService.activePlayer && MusicService.activePlayer.trackArtUrl && MusicService.activePlayer.playbackState === MprisPlaybackState.Playing) ? 0.35 : 0
                Behavior on opacity { NumberAnimation { duration: 1000 } }
                
                layer.enabled: true
                layer.effect: MultiEffect {
                    blurEnabled: true
                    blur: ThemeService.lockBackgroundBlur
                    blurMax: 128
                }
            }
        }
        
        Rectangle {
            anchors.fill: parent
            color: ThemeService.backgroundMain
            opacity: wallpaper.visible ? ThemeService.lockBackgroundOpacity : 1.0
        }

        Rectangle {
            anchors.fill: parent
            color: "transparent"
            opacity: 0.03
            Timer {
                interval: 50; running: true; repeat: true
                onTriggered: grain.x = Math.random() * -100
            }
            Rectangle { id: grain; width: parent.width + 100; height: parent.height; color: "white"; visible: false }
        }
    }
}
