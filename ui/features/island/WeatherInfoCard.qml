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
            text: isNaN(WeatherManager.currentTemperature) ? "--°" : Math.round(WeatherManager.currentTemperature) + "°"
        }
        
        StyledLabel {
            id: locationDisplay
            type: "caption"
            text: (WeatherManager.currentCityName || WeatherManager.configuredLocation || "NO LOCATION SET").toUpperCase()
            customColor: ThemeManager.contentSecondaryColor
            opacity: locationHoverHandler.hovered ? 1.0 : 0.8
            font.weight: Font.Bold
            letterSpacing: 1.5
            scale: locationHoverHandler.hovered ? 1.05 : 1.0
            
            Behavior on opacity { NumberAnimation { duration: 200 } }
            Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }
            
            TapHandler { 
                onTapped: root.inputRequested() 
            }
            HoverHandler { id: locationHoverHandler; cursorShape: Qt.PointingHandCursor }
        }
    }

    Rectangle { 
        width: 1; height: 30
        color: ThemeManager.contentOnBackgroundColor
        opacity: 0.1 
    }

    RowLayout {
        spacing: 8
        
        Image { 
            id: weatherVisualIcon
            source: WeatherManager.currentWeatherIconUrl || ""
            width: 40; height: 40
            fillMode: Image.PreserveAspectFit
            visible: !!WeatherManager.currentWeatherIconUrl 
        }
        
        ColumnLayout {
            spacing: 1
            
            StyledLabel {
                id: conditionLabel
                type: "label"
                text: (WeatherManager.currentCondition || "LOADING").toUpperCase()
                font.weight: Font.Bold
                letterSpacing: 0.5
            }
            
            StyledLabel {
                id: descriptionLabel
                type: "caption"
                text: WeatherManager.currentConditionDescription || "fetching data..."
                customColor: ThemeManager.contentSecondaryColor
                opacity: 0.8
                italic: true
            }
        }
    }
}
