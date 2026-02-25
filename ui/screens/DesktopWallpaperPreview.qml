import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Widgets
import qs.ui.shared
import qs.core

ColumnLayout {
    id: root
    
    spacing: 32
    Layout.fillWidth: false
    Layout.preferredWidth: 600
    Layout.alignment: Qt.AlignHCenter

    ColumnLayout {
        spacing: 4
        Layout.alignment: Qt.AlignHCenter
        
        Text { 
            id: previewHeaderLabel
            text: "DESKTOP PREVIEW"
            color: ThemeManager.contentOnBackgroundColor
            font.pixelSize: 10
            font.weight: Font.Black
            font.letterSpacing: 4
            opacity: 0.3
            Layout.alignment: Qt.AlignHCenter 
        }
        
        Rectangle { 
            id: headerIndicatorLine
            width: 40
            height: 2
            radius: 1
            color: ThemeManager.accentColor
            opacity: 0.4
            Layout.alignment: Qt.AlignHCenter 
        }
    }

    Item {
        id: monitorVisualContainer
        width: 600
        height: 337
        Layout.alignment: Qt.AlignHCenter
        
        Rectangle { 
            id: previewGlowEffect
            anchors.fill: parent
            anchors.margins: -10
            radius: 30
            color: ThemeManager.accentColor
            opacity: 0.04
            
            layer.enabled: true
            layer.effect: MultiEffect { 
                blurEnabled: true
                blur: 0.8
            } 
        }
        
        Rectangle {
            id: monitorDeviceFrame
            anchors.fill: parent
            radius: 24
            color: ThemeManager.backgroundPrimaryColor
            border.color: ThemeManager.outlinePrimaryColor
            border.width: 1
            
            ClippingRectangle {
                anchors.fill: parent
                anchors.margins: 6
                radius: 18
                color: "black"
                
                Image { 
                    id: wallpaperPreviewImage
                    anchors.fill: parent
                    source: WallpaperManager.previewWallpaperPath !== "" ? "file://" + WallpaperManager.previewWallpaperPath : ""
                    fillMode: Image.PreserveAspectCrop
                    opacity: status === Image.Ready ? 1.0 : 0.1
                    
                    Behavior on source { 
                        PropertyAnimation { 
                            duration: 600 
                        } 
                    } 
                }
                
                Rectangle { 
                    id: innerFrameBorder
                    anchors.fill: parent
                    radius: 18
                    color: "transparent"
                    border.color: "black"
                    border.width: 2
                    opacity: 0.4 
                }
            }
        }
    }
}
