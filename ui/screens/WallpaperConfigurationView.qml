import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.core

ColumnLayout {
    id: root
    
    spacing: 24
    Layout.fillWidth: true
    Layout.fillHeight: true
    
    ColumnLayout {
        spacing: 12
        Layout.fillWidth: true
        
        Text { 
            id: transitionTypeLabel
            text: "TRANSITION TYPE"
            color: ThemeManager.contentOnBackgroundColor
            font.pixelSize: 10
            font.weight: Font.Black
            font.letterSpacing: 2
            opacity: 0.4 
        }
        
        Row {
            id: transitionTypeSelectionRow
            spacing: 8
            Layout.fillWidth: true
            
            Repeater {
                model: ["simple", "grow", "fade", "wipe", "wave"]
                
                delegate: Rectangle {
                    id: transitionOptionDelegate
                    width: 70
                    height: 32
                    radius: 16
                    color: WallpaperManager.transitionType === modelData ? ThemeManager.accentColor : ThemeManager.contentOnBackgroundColor
                    opacity: WallpaperManager.transitionType === modelData ? 1.0 : 0.05
                    
                    Text { 
                        anchors.centerIn: parent
                        text: modelData.toUpperCase()
                        color: WallpaperManager.transitionType === modelData ? ThemeManager.contentPrimaryColor : ThemeManager.contentOnBackgroundColor
                        font.pixelSize: 8
                        font.weight: Font.Bold 
                    }
                    
                    TapHandler { 
                        onTapped: { 
                            WallpaperManager.transitionType = modelData 
                        } 
                    }
                    HoverHandler { 
                        id: optionHoverHandler
                        cursorShape: Qt.PointingHandCursor 
                    }
                    
                    scale: optionHoverHandler.hovered ? 1.05 : 1.0
                    Behavior on scale { 
                        NumberAnimation { 
                            duration: 200 
                        } 
                    }
                }
            }
        }
    }
    
    ColumnLayout {
        spacing: 12
        Layout.fillWidth: true
        
        Text { 
            id: slideshowIntervalLabel
            text: "SLIDESHOW INTERVAL"
            color: ThemeManager.contentOnBackgroundColor
            font.pixelSize: 10
            font.weight: Font.Black
            font.letterSpacing: 2
            opacity: 0.4 
        }
        
        RowLayout {
            id: slideshowIntervalRow
            spacing: 16
            
            Slider {
                id: intervalSlider
                Layout.fillWidth: true
                from: 60000
                to: 3600000
                stepSize: 60000
                value: WallpaperManager.slideshowInterval
                onMoved: { 
                    WallpaperManager.slideshowInterval = value 
                }
            }
            
            Text { 
                id: intervalValueLabel
                text: Math.round(WallpaperManager.slideshowInterval / 60000) + "m"
                color: ThemeManager.contentOnBackgroundColor
                font.pixelSize: 12
                font.weight: Font.Bold
                opacity: 0.6
                Layout.preferredWidth: 40 
            }
        }
    }
    
    Item { Layout.fillHeight: true }
}
