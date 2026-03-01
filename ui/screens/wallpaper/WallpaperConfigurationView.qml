import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.core
import qs.ui.shared

ColumnLayout {
    id: root
    
    spacing: 24
    Layout.fillWidth: true
    Layout.fillHeight: true
    
    ColumnLayout {
        spacing: 12
        Layout.fillWidth: true
        
        StyledLabel { 
            id: transitionTypeLabel
            text: "TRANSITION TYPE"
            type: "configHeader"
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
                    color: WallpaperManager.transitionType === modelData ? ThemeManager.accentColor : ThemeManager.surfacePrimaryColor
                    opacity: WallpaperManager.transitionType === modelData ? 1.0 : (optionHoverHandler.hovered ? 0.8 : 0.5)
                    
                    StyledLabel { 
                        anchors.centerIn: parent
                        text: modelData.toUpperCase()
                        type: "caption"
                        font.weight: Font.Bold 
                        customColor: WallpaperManager.transitionType === modelData ? ThemeManager.contentPrimaryColor : ThemeManager.contentOnBackgroundColor
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
                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }
        }
    }
    
    ColumnLayout {
        spacing: 12
        Layout.fillWidth: true
        
        StyledLabel { 
            id: slideshowIntervalLabel
            text: "SLIDESHOW INTERVAL"
            type: "configHeader"
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
            
            StyledLabel { 
                id: intervalValueLabel
                text: Math.round(WallpaperManager.slideshowInterval / 60000) + "m"
                type: "body"
                font.weight: Font.Bold
                opacity: 0.6
                Layout.preferredWidth: 40 
            }
        }
    }
    
    Item { Layout.fillHeight: true }
}
