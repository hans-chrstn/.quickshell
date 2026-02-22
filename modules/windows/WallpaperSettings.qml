import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.config
import qs.services

ColumnLayout {
    id: root
    spacing: 24
    Layout.fillWidth: true
    Layout.fillHeight: true
    
    ColumnLayout {
        spacing: 12
        Layout.fillWidth: true
        Text { 
            text: "TRANSITION TYPE"
            color: "white"
            font.pixelSize: 10
            font.weight: Font.Black
            font.letterSpacing: 2
            opacity: 0.4 
        }
        Row {
            spacing: 8
            Layout.fillWidth: true
            Repeater {
                model: ["simple", "grow", "fade", "wipe", "wave"]
                Rectangle {
                    width: 70
                    height: 32
                    radius: 16
                    color: WallpaperService.transitionType === modelData ? FrameConfig.accentColor : "white"
                    opacity: WallpaperService.transitionType === modelData ? 1.0 : 0.05
                    
                    Text { 
                        anchors.centerIn: parent
                        text: modelData.toUpperCase()
                        color: WallpaperService.transitionType === modelData ? "black" : "white"
                        font.pixelSize: 8
                        font.weight: Font.Bold 
                    }
                    TapHandler { onTapped: { WallpaperService.transitionType = modelData } }
                    HoverHandler { id: hT; cursorShape: Qt.PointingHandCursor }
                    scale: hT.hovered ? 1.05 : 1.0
                    Behavior on scale { NumberAnimation { duration: 200 } }
                }
            }
        }
    }
    
    ColumnLayout {
        spacing: 12
        Layout.fillWidth: true
        Text { 
            text: "SLIDESHOW INTERVAL"
            color: "white"
            font.pixelSize: 10
            font.weight: Font.Black
            font.letterSpacing: 2
            opacity: 0.4 
        }
        RowLayout {
            spacing: 16
            Slider {
                id: sSlider
                Layout.fillWidth: true
                from: 60000
                to: 3600000
                stepSize: 60000
                value: WallpaperService.slideshowInterval
                onMoved: { WallpaperService.slideshowInterval = value }
            }
            Text { 
                text: Math.round(WallpaperService.slideshowInterval / 60000) + "m"
                color: "white"
                font.pixelSize: 12
                font.weight: Font.Bold
                opacity: 0.6
                Layout.preferredWidth: 40 
            }
        }
    }
    
    Item { Layout.fillHeight: true }
}
