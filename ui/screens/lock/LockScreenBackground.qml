import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Services.Mpris
import qs.core
import qs.ui.shared.effects

Item {
    id: root
    
    property real relativeMouseX: 0
    property real relativeMouseY: 0

    implicitWidth: 1920
    implicitHeight: 1080

    OrganicBlobs {
        id: dynamicBackground
        anchors.fill: parent
        visible: !wallpaperImage.visible && !albumArtBackgroundImage.visible
        color1: Qt.rgba(ThemeManager.accentColor.r, ThemeManager.accentColor.g, ThemeManager.accentColor.b, 0.2)
        color2: Qt.rgba(ThemeManager.visualHighlightColor.r, ThemeManager.visualHighlightColor.g, ThemeManager.visualHighlightColor.b, 0.1)
        color3: ThemeManager.backgroundColor
    }

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

        Item {
            id: wallpaperContainer
            anchors.fill: parent
            visible: wallpaperImage.visible || albumArtBackgroundImage.visible

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
            }
        }
    }

    AdvancedGlass {
        id: glassEffect
        anchors.fill: parent
        source: parallaxLayer
        blurRadius: ThemeManager.lockBackgroundBlur * 4.0
        chromaticIntensity: 0.002
        overlayColor: ThemeManager.backgroundPrimaryColor
        overlayOpacity: 0.7
    }
}
