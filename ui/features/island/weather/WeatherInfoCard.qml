import QtQuick
import QtQuick.Layouts
import qs.core
import qs.ui.shared

RowLayout {
    id: root
    
    spacing: 20
    
    signal inputRequested()

    ColumnLayout {
        spacing: -4
        
        StyledLabel {
            id: temperatureDisplay
            type: "weatherTemp"
            text: {
                if (isNaN(WeatherManager.currentTemperature)) {
                    return "--°"
                }
                return Math.round(WeatherManager.currentTemperature) + "°"
            }
        }
        
        StyledLabel {
            id: locationDisplay
            type: "caption"
            text: {
                let city = WeatherManager.currentCityName || WeatherManager.configuredLocation || "NO LOCATION SET"
                return String(city).toUpperCase()
            }
            customColor: ThemeManager.contentSecondaryColor
            opacity: {
                if (locationHoverHandler.hovered) {
                    return 1.0
                }
                return 0.8
            }
            font.weight: Font.Bold
            letterSpacing: 1.5
            scale: {
                if (locationHoverHandler.hovered) {
                    return 1.05
                }
                return 1.0
            }
            
            Behavior on opacity { 
                NumberAnimation { 
                    duration: 200 
                } 
            }
            
            Behavior on scale { 
                NumberAnimation { 
                    duration: 200
                    easing.type: Easing.OutQuart 
                } 
            }
            
            TapHandler { 
                onTapped: {
                    root.inputRequested() 
                }
            }
            
            HoverHandler { 
                id: locationHoverHandler
                cursorShape: Qt.PointingHandCursor 
            }
        }
    }

    Rectangle { 
        width: 1
        height: 30
        color: ThemeManager.contentOnBackgroundColor
        opacity: 0.1 
    }

    RowLayout {
        spacing: 12
        
        Text {
            id: weatherVisualIcon
            text: {
                return WeatherManager.mapWeatherCodeToIcon(WeatherManager.currentWeatherCode)
            }
            font.pixelSize: 32
            color: ThemeManager.accentColor
            verticalAlignment: Text.AlignVCenter
        }
        
        ColumnLayout {
            spacing: 1
            
            StyledLabel {
                id: conditionLabel
                type: "label"
                text: {
                    let cond = WeatherManager.currentCondition || "LOADING"
                    return String(cond).toUpperCase()
                }
                font.weight: Font.Bold
                letterSpacing: 0.5
            }
            
            StyledLabel {
                id: descriptionLabel
                type: "caption"
                text: {
                    return WeatherManager.currentConditionDescription || "fetching data..."
                }
                customColor: ThemeManager.contentSecondaryColor
                opacity: 0.8
                italic: true
            }
        }
    }
}
