import QtQuick
import QtQuick.Layouts
import qs.services

RowLayout {
    id: root
    spacing: 20
    
    signal requestInput()

    ColumnLayout {
        spacing: -4
        Text {
            text: isNaN(WeatherManager.currentTemperature) ? "--°" : Math.round(WeatherManager.currentTemperature) + "°"
            color: ThemeManager.contentOnBackgroundColor; font.pixelSize: 42; font.weight: Font.DemiBold; font.letterSpacing: -1
        }
        Text {
            text: (WeatherManager.currentCityName || WeatherManager.configuredLocation || "NO LOCATION").toUpperCase()
            color: ThemeManager.contentSecondaryColor; opacity: 0.8; font.pixelSize: 9; font.weight: Font.Bold; font.letterSpacing: 1.5
            TapHandler { onTapped: root.requestInput() }
        }
    }

    Rectangle { width: 1; height: 30; color: ThemeManager.contentOnBackgroundColor; opacity: 0.1 }

    RowLayout {
        spacing: 8
        Image { 
            source: WeatherManager.currentWeatherIconUrl || ""; width: 40; height: 40; fillMode: Image.PreserveAspectFit
            visible: !!WeatherManager.currentWeatherIconUrl 
        }
        ColumnLayout {
            spacing: 1
            Text {
                text: (WeatherManager.currentCondition || "LOADING").toUpperCase()
                color: ThemeManager.contentOnBackgroundColor; font.pixelSize: 11; font.weight: Font.Bold; font.letterSpacing: 0.5
            }
            Text {
                text: WeatherManager.currentConditionDescription || "fetching..."
                color: ThemeManager.contentSecondaryColor; opacity: 0.8; font.pixelSize: 9; font.italic: true
            }
        }
    }
}
