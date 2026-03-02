import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Services.Mpris
import qs.core

Item {
    id: root
    
    property real relativeMouseX: 0
    property real relativeMouseY: 0

    implicitWidth: 1920
    implicitHeight: 1080

    Item {
        id: parallaxLayer
        anchors.fill: parent
        scale: 1.05
        
        transform: Translate {
            x: root.relativeMouseX * -ThemeManager.lockParallaxIntensity
            y: root.relativeMouseY * -ThemeManager.lockParallaxIntensity
            Behavior on x { 
                NumberAnimation { 
                    duration: 1000
                    easing.type: Easing.OutCubic 
                } 
            }
            Behavior on y { 
                NumberAnimation { 
                    duration: 1000
                    easing.type: Easing.OutCubic 
                } 
            }
        }

        Image {
            id: wallpaperImage
            anchors.fill: parent
            source: {
                let path = WallpaperManager.activeWallpaperPath
                if (!path) {
                    return ""
                }
                return (path.startsWith("/") ? "file://" : "") + path
            }
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
            id: albumArtBackgroundImage
            anchors.fill: parent
            source: MusicManager.activePlayer ? MusicManager.activePlayer.trackArtUrl : ""
            fillMode: Image.PreserveAspectCrop
            opacity: (MusicManager.activePlayer && MusicManager.activePlayer.trackArtUrl && MusicManager.activePlayer.playbackState === MprisPlaybackState.Playing) ? 0.35 : 0
            
            Behavior on opacity { 
                NumberAnimation { 
                    duration: 1000 
                } 
            }
            
            layer.enabled: true
            layer.effect: MultiEffect {
                blurEnabled: true
                blur: ThemeManager.lockBackgroundBlur
                blurMax: 128
            }
        }
    }
    
    Rectangle {
        id: overlayDimmer
        anchors.fill: parent
        color: ThemeManager.backgroundPrimaryColor
        opacity: wallpaperImage.visible ? ThemeManager.lockBackgroundOpacity : 1.0
    }

    Rectangle {
        id: noiseGrainLayer
        anchors.fill: parent
        color: "transparent"
        opacity: 0.03
        
        Timer {
            interval: 50
            running: true
            repeat: true
            onTriggered: {
                grainVisual.x = Math.random() * -100
            }
        }
        
        Rectangle { 
            id: grainVisual
            width: parent.width + 100
            height: parent.height
            color: "white"
            visible: false 
        }
    }
}
