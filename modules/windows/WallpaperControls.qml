import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import QtMultimedia
import Quickshell
import Quickshell.Widgets
import qs.components
import qs.services

RowLayout {
    id: root
    spacing: 20
    Layout.alignment: Qt.AlignHCenter
    
    property var rootWindow: null

    function playComplete() { SfxService.playComplete() }

    Item {
        width: 180
        height: 48
        property bool canSlideshow: FileBrowserService.hasImages
        
        opacity: canSlideshow ? 1.0 : 0.0
        scale: canSlideshow ? 1.0 : 0.8
        visible: opacity > 0.01
        
        Behavior on opacity { NumberAnimation { duration: 300 } }
        Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }
        
        Rectangle {
            anchors.fill: parent
            radius: 24
            color: ThemeService.surfaceVariantStrong
            border.color: hSlide.hovered ? ThemeService.accentColor : ThemeService.outlineMain
            border.width: 1
            
            Text { 
                anchors.centerIn: parent
                text: "󰐊  SLIDESHOW"
                color: ThemeService.backgroundContent
                font.pixelSize: 11
                font.weight: Font.Bold
                font.letterSpacing: 1
                opacity: hSlide.hovered ? 1.0 : 0.6 
            }
            scale: hSlide.hovered ? 1.02 : 1.0
            Behavior on scale { NumberAnimation { duration: 200 } }
        }
        TapHandler { 
            onTapped: { 
                WallpaperService.startSlideshow(FileBrowserService.currentPath)
                if (root.rootWindow) root.rootWindow.visible = false 
                playComplete()
            } 
        }
        HoverHandler { id: hSlide; cursorShape: Qt.PointingHandCursor }
    }

    Item {
        width: 140
        height: 48
        opacity: WallpaperService.lastWallpaper !== "" ? 1.0 : 0.3
        
        Rectangle {
            id: revBg
            anchors.fill: parent
            radius: 24
            color: ThemeService.surfaceVariantStrong
            border.color: hRev.hovered ? ThemeService.backgroundContent : ThemeService.outlineMain
            border.width: 1
            
            Text { 
                anchors.centerIn: parent
                text: "󰕌  REVERT"
                color: ThemeService.backgroundContent
                font.pixelSize: 11
                font.weight: Font.Bold
                font.letterSpacing: 1
                opacity: hRev.hovered ? 1.0 : 0.6 
            }
            scale: hRev.hovered ? 1.02 : 1.0
            Behavior on scale { NumberAnimation { duration: 200 } }
            Behavior on border.color { ColorAnimation { duration: 200 } }
        }
        TapHandler { enabled: WallpaperService.lastWallpaper !== ""; onTapped: WallpaperService.revert() }
        HoverHandler { id: hRev; cursorShape: Qt.PointingHandCursor }
    }

    Item {
        width: 240
        height: 48
        readonly property bool hasChanges: WallpaperService.previewWallpaper !== "" && WallpaperService.previewWallpaper !== WallpaperService.activeWallpaper
        
        opacity: hasChanges ? 1.0 : 0.0
        scale: hasChanges ? 1.0 : 0.8
        visible: opacity > 0.01
        
        Behavior on opacity { NumberAnimation { duration: 300 } }
        Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }
        
        Rectangle {
            id: appBg
            anchors.fill: parent
            radius: 24
            color: ThemeService.accentColor
            
            Rectangle { 
                anchors.fill: parent
                anchors.margins: -8
                radius: 28
                color: ThemeService.accentColor
                opacity: hApp.hovered ? 0.02 : 0.0
                z: -1
                layer.enabled: true
                layer.effect: MultiEffect { blurEnabled: true; blur: 0.6 }
                Behavior on opacity { NumberAnimation { duration: 300 } } 
            }
            
            Rectangle { 
                anchors.fill: parent
                anchors.margins: 1
                radius: 23
                color: "transparent"
                border.color: ThemeService.primaryContent
                border.width: 1 
                opacity: 0.3
            }
            
            Text { 
                anchors.centerIn: parent
                text: "󰄬  CONFIRM CHANGES"
                color: ThemeService.primaryContent
                font.pixelSize: 11
                font.weight: Font.Black
                font.letterSpacing: 1 
            }
            scale: hApp.hovered ? 1.03 : 1.0
            Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
        }
        TapHandler { 
            onTapped: { 
                WallpaperService.apply()
                if (root.rootWindow) root.rootWindow.visible = false 
                playComplete()
            } 
        }
        HoverHandler { id: hApp; cursorShape: Qt.PointingHandCursor }
    }
}
