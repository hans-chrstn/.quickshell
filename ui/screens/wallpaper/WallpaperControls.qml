import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import qs.ui.shared
import qs.core

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

    function playComplete() { SoundManager.playSuccess() }

    RowLayout {
        anchors.fill: parent
        spacing: 20

        Item {
            id: slideshowBtn
            width: 180; height: 48
            property bool canSlideshow: FileBrowserManager.containsImages
            opacity: canSlideshow ? 1.0 : 0.0
            scale: canSlideshow ? 1.0 : 0.8
            visible: opacity > 0.01
            
            focus: true 
            
            function startSlide() {
                WallpaperManager.startSlideshow(FileBrowserManager.currentPath)
                if (root.rootWindow) root.rootWindow.visible = false 
                playComplete()
            }

            Keys.onSpacePressed: startSlide()
            Keys.onEnterPressed: startSlide()
            Keys.onReturnPressed: startSlide()

            Rectangle {
                anchors.fill: parent; radius: 24
                color: ThemeManager.surfaceVariantStrongColor
                border.color: parent.activeFocus ? "white" : (hSlide.hovered ? ThemeManager.accentColor : ThemeManager.outlinePrimaryColor)
                border.width: parent.activeFocus ? 2 : 1
                StyledLabel { 
                    anchors.centerIn: parent; text: "󰐊  SLIDESHOW"
                    type: "caption"
                    font.weight: Font.Bold; font.letterSpacing: 1; font.pixelSize: 11; opacity: (hSlide.hovered || parent.activeFocus) ? 1.0 : 0.6 
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
            opacity: WallpaperManager.previousWallpaperPath !== "" ? 1.0 : 0.3
            
            Keys.onSpacePressed: WallpaperManager.revertWallpaper()
            Keys.onEnterPressed: WallpaperManager.revertWallpaper()
            Keys.onReturnPressed: WallpaperManager.revertWallpaper()

            Rectangle {
                anchors.fill: parent; radius: 24
                color: ThemeManager.surfaceVariantStrongColor
                border.color: parent.activeFocus ? "white" : (hRev.hovered ? ThemeManager.contentOnBackgroundColor : ThemeManager.outlinePrimaryColor)
                border.width: parent.activeFocus ? 2 : 1
                StyledLabel { 
                    anchors.centerIn: parent; text: "󰕌  REVERT"
                    type: "caption"
                    font.weight: Font.Bold; font.letterSpacing: 1; font.pixelSize: 11; opacity: (hRev.hovered || parent.activeFocus) ? 1.0 : 0.6 
                }
                scale: (hRev.hovered || parent.activeFocus) ? 1.02 : 1.0
                Behavior on scale { NumberAnimation { duration: 200 } }
            }
            TapHandler { enabled: WallpaperManager.previousWallpaperPath !== ""; onTapped: WallpaperManager.revertWallpaper() }
            HoverHandler { id: hRev; cursorShape: Qt.PointingHandCursor }
        }

        Item {
            id: applyBtn
            width: 240; height: 48
            readonly property bool hasChanges: WallpaperManager.previewWallpaperPath !== "" && WallpaperManager.previewWallpaperPath !== WallpaperManager.activeWallpaperPath
            opacity: hasChanges ? 1.0 : 0.0
            scale: hasChanges ? 1.0 : 0.8
            visible: opacity > 0.01
            
            function doConfirm() {
                WallpaperManager.applyWallpaper()
                if (root.rootWindow) root.rootWindow.visible = false 
                playComplete()
            }

            Keys.onSpacePressed: doConfirm()
            Keys.onEnterPressed: doConfirm()
            Keys.onReturnPressed: doConfirm()

            Rectangle {
                anchors.fill: parent; radius: 24; color: ThemeManager.accentColor
                border.color: parent.activeFocus ? "white" : "transparent"; border.width: parent.activeFocus ? 2 : 0
                
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: (hApp && hApp.hovered) || applyBtn.activeFocus
                    shadowColor: ThemeManager.accentColor
                    shadowOpacity: 0.3
                    shadowBlur: 0.6
                }

                StyledLabel { 
                    anchors.centerIn: parent; text: "󰄬  CONFIRM CHANGES"
                    type: "caption"
                    customColor: ThemeManager.contentPrimaryColor; font.weight: Font.Black; font.letterSpacing: 1; font.pixelSize: 11 
                }
                scale: (hApp.hovered || parent.activeFocus) ? 1.03 : 1.0
                Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
            }
            TapHandler { onTapped: applyBtn.doConfirm() }
            HoverHandler { id: hApp; cursorShape: Qt.PointingHandCursor }
        }
    }
}
