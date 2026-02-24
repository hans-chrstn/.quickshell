import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import qs.components
import qs.services

FocusScope {
    id: root
    
    width: 600
    Layout.preferredWidth: 600
    Layout.fillWidth: false
    Layout.preferredHeight: 48
    Layout.alignment: Qt.AlignHCenter
    
    property var rootWindow: null
    
    Keys.onLeftPressed: {
        if (undoBtn.activeFocus) slideshowBtn.forceActiveFocus()
        else if (applyBtn.activeFocus) undoBtn.forceActiveFocus()
    }
    Keys.onRightPressed: {
        if (slideshowBtn.activeFocus) undoBtn.forceActiveFocus()
        else if (undoBtn.activeFocus) applyBtn.forceActiveFocus()
    }

    property alias slideBtn: slideshowBtn
    property alias revertBtn: undoBtn
    property alias confirmBtn: applyBtn

    function playComplete() { SfxService.playComplete() }

    RowLayout {
        anchors.fill: parent
        spacing: 20

        Item {
            id: slideshowBtn
            width: 180; height: 48
            property bool canSlideshow: FileBrowserService.hasImages
            opacity: canSlideshow ? 1.0 : 0.0
            scale: canSlideshow ? 1.0 : 0.8
            visible: opacity > 0.01
            
            focus: true 
            
            function startSlide() {
                WallpaperService.startSlideshow(FileBrowserService.currentPath)
                if (root.rootWindow) root.rootWindow.visible = false 
                playComplete()
            }

            Keys.onSpacePressed: startSlide()
            Keys.onEnterPressed: startSlide()
            Keys.onReturnPressed: startSlide()

            Rectangle {
                anchors.fill: parent; radius: 24
                color: ThemeService.surfaceVariantStrong
                border.color: parent.activeFocus ? "white" : (hSlide.hovered ? ThemeService.accentColor : ThemeService.outlineMain)
                border.width: parent.activeFocus ? 2 : 1
                Text { 
                    anchors.centerIn: parent; text: "󰐊  SLIDESHOW"
                    color: ThemeService.backgroundContent; font.pixelSize: 11; font.weight: Font.Bold; font.letterSpacing: 1; opacity: (hSlide.hovered || parent.activeFocus) ? 1.0 : 0.6 
                }
                scale: (hSlide.hovered || parent.activeFocus) ? 1.02 : 1.0
                Behavior on scale { NumberAnimation { duration: 200 } }
            }
            TapHandler { onTapped: slideshowBtn.startSlide() }
            HoverHandler { id: hSlide; cursorShape: Qt.PointingHandCursor }
        }

        Item {
            id: undoBtn
            width: 140; height: 48
            opacity: WallpaperService.lastWallpaper !== "" ? 1.0 : 0.3
            
            Keys.onSpacePressed: WallpaperService.revert()
            Keys.onEnterPressed: WallpaperService.revert()
            Keys.onReturnPressed: WallpaperService.revert()

            Rectangle {
                anchors.fill: parent; radius: 24
                color: ThemeService.surfaceVariantStrong
                border.color: parent.activeFocus ? "white" : (hRev.hovered ? ThemeService.backgroundContent : ThemeService.outlineMain)
                border.width: parent.activeFocus ? 2 : 1
                Text { 
                    anchors.centerIn: parent; text: "󰕌  REVERT"
                    color: ThemeService.backgroundContent; font.pixelSize: 11; font.weight: Font.Bold; font.letterSpacing: 1; opacity: (hRev.hovered || parent.activeFocus) ? 1.0 : 0.6 
                }
                scale: (hRev.hovered || parent.activeFocus) ? 1.02 : 1.0
                Behavior on scale { NumberAnimation { duration: 200 } }
            }
            TapHandler { enabled: WallpaperService.lastWallpaper !== ""; onTapped: WallpaperService.revert() }
            HoverHandler { id: hRev; cursorShape: Qt.PointingHandCursor }
        }

        Item {
            id: applyBtn
            width: 240; height: 48
            readonly property bool hasChanges: WallpaperService.previewWallpaper !== "" && WallpaperService.previewWallpaper !== WallpaperService.activeWallpaper
            opacity: hasChanges ? 1.0 : 0.0
            scale: hasChanges ? 1.0 : 0.8
            visible: opacity > 0.01
            
            function doConfirm() {
                WallpaperService.apply()
                if (root.rootWindow) root.rootWindow.visible = false 
                playComplete()
            }

            Keys.onSpacePressed: doConfirm()
            Keys.onEnterPressed: doConfirm()
            Keys.onReturnPressed: doConfirm()

            Rectangle {
                anchors.fill: parent; radius: 24; color: ThemeService.accentColor
                border.color: parent.activeFocus ? "white" : "transparent"; border.width: parent.activeFocus ? 2 : 0
                
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: (hApp && hApp.hovered) || (parent && parent.activeFocus)
                    shadowColor: ThemeService.accentColor
                    shadowOpacity: 0.3
                    shadowBlur: 0.6
                }

                Text { 
                    anchors.centerIn: parent; text: "󰄬  CONFIRM CHANGES"
                    color: ThemeService.primaryContent; font.pixelSize: 11; font.weight: Font.Black; font.letterSpacing: 1 
                }
                scale: (hApp.hovered || parent.activeFocus) ? 1.03 : 1.0
                Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
            }
            TapHandler { onTapped: applyBtn.doConfirm() }
            HoverHandler { id: hApp; cursorShape: Qt.PointingHandCursor }
        }
    }
}
