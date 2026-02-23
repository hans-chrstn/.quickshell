import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Widgets
import qs.components
import qs.services

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
            text: "DESKTOP PREVIEW"
            color: ThemeService.backgroundContent
            font.pixelSize: 10
            font.weight: Font.Black
            font.letterSpacing: 4
            opacity: 0.3
            Layout.alignment: Qt.AlignHCenter 
        }
        Rectangle { 
            width: 40
            height: 2
            radius: 1
            color: ThemeService.accentColor
            opacity: 0.4
            Layout.alignment: Qt.AlignHCenter 
        }
    }

    Item {
        width: 600
        height: 337
        Layout.alignment: Qt.AlignHCenter
        
        Rectangle { 
            anchors.fill: parent
            anchors.margins: -10
            radius: 30
            color: ThemeService.accentColor
            opacity: 0.04
            layer.enabled: true
            layer.effect: MultiEffect { 
                blurEnabled: true; blur: 0.8
            } 
        }
        
        Rectangle {
            id: monitorFrame
            anchors.fill: parent
            radius: 24
            color: ThemeService.backgroundMain
            border.color: ThemeService.outlineMain
            border.width: 1
            
            ClippingRectangle {
                anchors.fill: parent
                anchors.margins: 6
                radius: 18
                color: "black"
                
                Image { 
                    id: previewImg
                    anchors.fill: parent
                    source: WallpaperService.previewWallpaper !== "" ? "file://" + WallpaperService.previewWallpaper : ""
                    fillMode: Image.PreserveAspectCrop
                    opacity: status === Image.Ready ? 1.0 : 0.1
                    Behavior on source { PropertyAnimation { duration: 600 } } 
                }
                
                Rectangle { 
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
