pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.core

Singleton {
    id: root

    property string configuredLocation: ""
    property string currentCityName: ""
    
    property int currentWeatherCode: 0
    property string currentCondition: "Clear"
    property string currentConditionDescription: "clear sky"
    property real currentTemperature: NaN
    property real feelsLike: NaN
    property real humidity: 0
    property real windSpeed: 0
    property real uvIndex: 0
    
    property string currentWeatherIconUrl: ""
    property string currentBackgroundUrl: weatherBackgroundMap["Clear"]

    readonly property ListModel forecastStore: ListModel {
    }

    readonly property string weatherCacheDirectory: {
        return Quickshell.cachePath("weather_images")
    }
    
    readonly property string locationConfigFilePath: {
        return Quickshell.cachePath("location")
    }

    readonly property var weatherBackgroundMap: {
        return {
            "Clear": "https://images.unsplash.com/photo-1504608524841-42fe6f032b4b?q=80&w=1000&auto=format&fit=crop",
            "Clouds": "https://images.unsplash.com/photo-1534088568595-a066f410bcda?q=80&w=1000&auto=format&fit=crop",
            "Rain": "https://images.unsplash.com/photo-1534274988757-a28bf1a57c17?q=80&w=1000&auto=format&fit=crop",
            "Snow": "https://images.unsplash.com/photo-1491002052546-bf38f186af56?q=80&w=1000&auto=format&fit=crop",
            "Thunderstorm": "https://images.unsplash.com/photo-1605727216801-e27ce1d0cc28?q=80&w=1000&auto=format&fit=crop"
        }
    }

    function updateLocalBackground() {
        let condition = root.currentCondition || "Clear"
        let localPath = root.weatherCacheDirectory + "/weather_" + condition + ".jpg"
        
        backgroundCheckProcess.command = [
            "test", 
            "-f", 
            localPath
        ]
        backgroundCheckProcess.running = true
    }

    Process {
        id: backgroundCheckProcess
        onExited: (code) => {
            let condition = root.currentCondition || "Clear"
            let localPath = root.weatherCacheDirectory + "/weather_" + condition + ".jpg"
            
            if (code === 0) {
                root.currentBackgroundUrl = "file://" + localPath
            } else {
                backgroundDownloadProcess.command = [
                    "curl", 
                    "-L", 
                    "--create-dirs", 
                    root.weatherBackgroundMap[condition], 
                    "-o", 
                    localPath
                ]
                backgroundDownloadProcess.running = true
                root.currentBackgroundUrl = root.weatherBackgroundMap[condition]
            }
        }
    }

    Process { 
        id: backgroundDownloadProcess
        onExited: (code) => {
            if (code === 0) {
                root.updateLocalBackground()
            }
        }
    }

    onCurrentConditionChanged: {
        root.updateLocalBackground()
    }

    function mapWeatherCodeToCondition(code) {
        if (code <= 1) return "Clear"
        if (code <= 3) return "Clouds"
        if (code <= 67) return "Rain"
        if (code <= 77) return "Snow"
        if (code <= 99) return "Thunderstorm"
        return "Clear"
    }

    function mapWeatherCodeToIcon(code) {
        const icons = {
            0: "󰖙", 1: "󰖙", 2: "󰖕", 3: "󰖐",
            45: "󰖑", 48: "󰖑",
            51: "󰖗", 53: "󰖗", 55: "󰖗",
            61: "󰖗", 63: "󰖗", 65: "󰖗",
            71: "󰖘", 73: "󰖘", 75: "󰖘", 77: "󰖘",
            80: "󰖗", 81: "󰖗", 82: "󰖗",
            85: "󰖘", 86: "󰖘",
            95: "󰖓", 96: "󰖓", 99: "󰖓"
        }
        return icons[code] || "󰖙"
    }

    function mapWeatherCodeToDescription(code) {
        const descriptions = {
            0: "clear sky", 1: "mainly clear", 2: "partly cloudy", 3: "overcast",
            45: "fog", 48: "depositing rime fog",
            51: "light drizzle", 53: "moderate drizzle", 55: "dense drizzle",
            61: "slight rain", 63: "moderate rain", 65: "heavy rain",
            71: "slight snow fall", 73: "moderate snow fall", 75: "heavy snow fall",
            77: "snow grains",
            80: "slight rain showers", 81: "moderate rain showers", 82: "violent rain showers",
            85: "slight snow showers", 86: "heavy snow showers",
            95: "thunderstorm", 96: "thunderstorm with slight hail", 99: "thunderstorm with heavy hail"
        }
        return descriptions[code] || "unknown"
    }

    function fetchCityNameFromCoordinates(locationString) {
        if (!locationString || !locationString.includes(",")) {
            return
        }
        
        let coords = locationString.split(",")
        let latitude = coords[0].trim()
        let longitude = coords[1].trim()
        let url = `https://nominatim.openstreetmap.org/reverse?lat=${latitude}&lon=${longitude}&format=json&zoom=10`
        
        let xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        let data = JSON.parse(xhr.responseText)
                        if (data && data.address) {
                            let address = data.address
                            root.currentCityName = address.city || address.town || address.village || address.municipality || address.county || address.state || address.country || "Location Set"
                        } else {
                            root.currentCityName = "Location Set"
                        }
                    } catch (error) {
                        root.currentCityName = "Location Set"
                    }
                } else {
                    root.currentCityName = "Location Set"
                }
            }
        }
        xhr.open("GET", url)
        xhr.setRequestHeader("User-Agent", "Quickshell/1.0")
        xhr.send()
    }

    FileView {
        id: locationConfigFile
        path: root.locationConfigFilePath
        onLoaded: {
            let content = text().trim()
            if (content && content.includes(",")) {
                root.configuredLocation = content
                root.fetchCityNameFromCoordinates(content)
                root.fetchLatestWeather()
            }
        }
    }

    function updateLocation(newLocation) {
        if (!newLocation || !newLocation.includes(",")) {
            return
        }
        
        let sanitizedLocation = newLocation.replace(/[^0-9.,-]/g, "")
        if (!sanitizedLocation.includes(",")) {
            return
        }

        locationConfigFile.setText(sanitizedLocation)
        root.configuredLocation = sanitizedLocation
        root.fetchCityNameFromCoordinates(sanitizedLocation)
        root.fetchLatestWeather()
    }

    function fetchLatestWeather() {
        let location = root.configuredLocation
        if (!location || location === "") {
            return
        }

        let latitude, longitude
        if (location.includes(",")) {
            let coords = location.split(",")
            latitude = coords[0].trim()
            longitude = coords[1].trim()
        } else {
            latitude = "51.5074"
            longitude = "-0.1278"
        }

        let url = `https://api.open-meteo.com/v1/forecast?latitude=${latitude}&longitude=${longitude}&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m&daily=weather_code,temperature_2m_max,temperature_2m_min,uv_index_max&timezone=auto`
        
        try {
            let xhr = new XMLHttpRequest()
            xhr.onreadystatechange = function() {
                if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                    try {
                        let data = JSON.parse(xhr.responseText)
                        if (data && data.current) {
                            let wc = data.current.weather_code
                            root.currentWeatherCode = wc
                            root.currentCondition = root.mapWeatherCodeToCondition(wc)
                            root.currentConditionDescription = root.mapWeatherCodeToDescription(wc)
                            root.currentTemperature = data.current.temperature_2m
                            root.feelsLike = data.current.apparent_temperature
                            root.humidity = data.current.relative_humidity_2m
                            root.windSpeed = data.current.wind_speed_10m
                            
                            if (data.daily) {
                                root.uvIndex = data.daily.uv_index_max[0]
                                root.forecastStore.clear()
                                
                                for (let i = 0; i < data.daily.time.length; i++) {
                                    let date = new Date(data.daily.time[i])
                                    let dayName = date.toLocaleDateString(Qt.locale(), "ddd")
                                    if (i === 0) dayName = "Today"
                                    
                                    root.forecastStore.append({
                                        "day": dayName,
                                        "icon": root.mapWeatherCodeToIcon(data.daily.weather_code[i]),
                                        "high": data.daily.temperature_2m_max[i],
                                        "low": data.daily.temperature_2m_min[i]
                                    })
                                }
                            }
                        }
                    } catch (error) {
                        console.error("WeatherManager: Parse Failed")
                    }
                }
            }
            xhr.open("GET", url)
            xhr.send()
        } catch (error) {
            console.error("WeatherManager: Fetch Failed")
        }
    }

    Timer { 
        interval: 1800000 
        running: true 
        repeat: true 
        triggeredOnStart: false
        onTriggered: {
            root.fetchLatestWeather()
        }
    }
}
