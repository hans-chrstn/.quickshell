import QtQuick
import QtQuick.Layouts
import qs.core

RowLayout {
    id: root
    
    spacing: 20
    
    signal inputRequested()

    ColumnLayout {
        spacing: -4
        
        Text {
            id: temperatureDisplay
            text: isNaN(WeatherManager.currentTemperature) ? "--°" : Math.round(WeatherManager.currentTemperature) + "°"
            color: ThemeManager.contentOnBackgroundColor
            font.pixelSize: 42
            font.weight: Font.DemiBold
            font.letterSpacing: -1
        }
        
        Text {
            id: locationDisplay
            text: (WeatherManager.currentCityName || WeatherManager.configuredLocation || "NO LOCATION SET").toUpperCase()
            color: ThemeManager.contentSecondaryColor
            opacity: 0.8
            font.pixelSize: 9
            font.weight: Font.Bold
            font.letterSpacing: 1.5
            
            TapHandler { 
                onTapped: root.inputRequested() 
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
        spacing: 8
        
        Image { 
            id: weatherVisualIcon
            source: WeatherManager.currentWeatherIconUrl || ""
            width: 40
            height: 40
            fillMode: Image.PreserveAspectFit
            visible: !!WeatherManager.currentWeatherIconUrl 
        }
        
        ColumnLayout {
            spacing: 1
            
            Text {
                id: conditionLabel
                text: (WeatherManager.currentCondition || "LOADING").toUpperCase()
                color: ThemeManager.contentOnBackgroundColor
                font.pixelSize: 11
                font.weight: Font.Bold
                font.letterSpacing: 0.5
            }
            
            Text {
                id: descriptionLabel
                text: WeatherManager.currentConditionDescription || "fetching data..."
                color: ThemeManager.contentSecondaryColor
                opacity: 0.8
                font.pixelSize: 9
                font.italic: true
            }
        }
    }
}
