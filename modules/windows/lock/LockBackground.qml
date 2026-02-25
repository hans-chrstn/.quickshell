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
                x: root.mouseX * -ThemeManager.lockParallaxIntensity
                y: root.mouseY * -ThemeManager.lockParallaxIntensity
                Behavior on x { NumberAnimation { duration: 1000; easing.type: Easing.OutCubic } }
                Behavior on y { NumberAnimation { duration: 1000; easing.type: Easing.OutCubic } }
            }

            Image {
                id: wallpaper
                anchors.fill: parent
                source: (WallpaperManager.activeWallpaperPath.startsWith("/") ? "file://" : "") + WallpaperManager.activeWallpaperPath
                fillMode: Image.PreserveAspectCrop
                visible: WallpaperManager.activeWallpaperPath !== ""
                
                layer.enabled: true
                layer.effect: MultiEffect {
                    blurEnabled: true
                    blur: ThemeManager.lockBackgroundBlur
                    blurMax: 64
                }
            }

            Image {
                id: trackArtBg
                anchors.fill: parent
                source: MusicManager.activePlayer ? MusicManager.activePlayer.trackArtUrl : ""
                fillMode: Image.PreserveAspectCrop
                opacity: (MusicManager.activePlayer && MusicManager.activePlayer.trackArtUrl && MusicManager.activePlayer.playbackState === MprisPlaybackState.Playing) ? 0.35 : 0
                Behavior on opacity { NumberAnimation { duration: 1000 } }
                
                layer.enabled: true
                layer.effect: MultiEffect {
                    blurEnabled: true
                    blur: ThemeManager.lockBackgroundBlur
                    blurMax: 128
                }
            }
        }
        
        Rectangle {
            anchors.fill: parent
            color: ThemeManager.backgroundPrimaryColor
            opacity: wallpaper.visible ? ThemeManager.lockBackgroundOpacity : 1.0
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
