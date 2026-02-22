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
            text: isNaN(WeatherService.weatherTemp) ? "--°" : Math.round(WeatherService.weatherTemp) + "°"
            color: ThemeService.backgroundContent; font.pixelSize: 42; font.weight: Font.DemiBold; font.letterSpacing: -1
        }
        Text {
            text: (WeatherService.cityName || WeatherService.weatherLocation || "NO LOCATION").toUpperCase()
            color: ThemeService.secondaryContent; opacity: 0.8; font.pixelSize: 9; font.weight: Font.Bold; font.letterSpacing: 1.5
            TapHandler { onTapped: root.requestInput() }
        }
    }

    Rectangle { width: 1; height: 30; color: ThemeService.backgroundContent; opacity: 0.1 }

    RowLayout {
        spacing: 8
        Image { 
            source: WeatherService.weatherIconUrl || ""; width: 40; height: 40; fillMode: Image.PreserveAspectFit
            visible: !!WeatherService.weatherIconUrl 
        }
        ColumnLayout {
            spacing: 1
            Text {
                text: (WeatherService.weatherCondition || "LOADING").toUpperCase()
                color: ThemeService.backgroundContent; font.pixelSize: 11; font.weight: Font.Bold; font.letterSpacing: 0.5
            }
            Text {
                text: WeatherService.weatherDescription || "fetching..."
                color: ThemeService.secondaryContent; opacity: 0.8; font.pixelSize: 9; font.italic: true
            }
        }
    }
}
