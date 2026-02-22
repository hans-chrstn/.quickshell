pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

Singleton {
    id: root

    property string weatherLocation: ""
    property string cityName: ""
    property string weatherCondition: ""
    property string weatherDescription: ""
    property real weatherTemp: NaN
    property string weatherIconUrl: ""
    property string currentBgSource: bgMap["Clear"]

    readonly property string cacheDir: Quickshell.cachePath("weather_images")
    readonly property string locFilePath: Quickshell.cachePath("location")

    readonly property var bgMap: {
        "Clear": "https://images.unsplash.com/photo-1504608524841-42fe6f032b4b?q=80&w=1000&auto=format&fit=crop",
        "Clouds": "https://images.unsplash.com/photo-1534088568595-a066f410bcda?q=80&w=1000&auto=format&fit=crop",
        "Rain": "https://images.unsplash.com/photo-1534274988757-a28bf1a57c17?q=80&w=1000&auto=format&fit=crop",
        "Snow": "https://images.unsplash.com/photo-1491002052546-bf38f186af56?q=80&w=1000&auto=format&fit=crop",
        "Thunderstorm": "https://images.unsplash.com/photo-1605727216801-e27ce1d0cc28?q=80&w=1000&auto=format&fit=crop"
    }

    function updateBackground() {
        let condition = root.weatherCondition || "Clear";
        let localPath = root.cacheDir + "/weather_" + condition + ".jpg";
        
        checkProcess.command = ["test", "-f", localPath];
        checkProcess.running = true;
    }

    Process {
        id: checkProcess
        onExited: (code) => {
            let condition = root.weatherCondition || "Clear";
            let localPath = root.cacheDir + "/weather_" + condition + ".jpg";
            if (code === 0) {
                root.currentBgSource = "file://" + localPath;
            } else {
                downloadProcess.command = ["curl", "-L", "--create-dirs", root.bgMap[condition], "-o", localPath];
                downloadProcess.running = true;
                root.currentBgSource = root.bgMap[condition];
            }
        }
    }

    Process { 
        id: downloadProcess
        onExited: (code) => {
            if (code === 0) root.updateBackground();
        }
    }

    onWeatherConditionChanged: updateBackground()

    function getWeatherCondition(code) {
        if (code <= 1) return "Clear";
        if (code <= 3) return "Clouds";
        if (code <= 67) return "Rain";
        if (code <= 77) return "Snow";
        if (code <= 99) return "Thunderstorm";
        return "Clear";
    }

    function fetchCityName(loc) {
        if (!loc || !loc.includes(",")) return;
        let [lat, lon] = loc.split(",");
        let url = `https://nominatim.openstreetmap.org/reverse?lat=${lat.trim()}&lon=${lon.trim()}&format=json&zoom=10`;
        
        let xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                try {
                    let data = JSON.parse(xhr.responseText);
                    if (data && data.address) {
                        let addr = data.address;
                        let name = addr.city || addr.town || addr.village || addr.municipality || addr.county || addr.state || addr.country || "Unknown City";
                        root.cityName = name;
                    }
                } catch (e) {
                    root.cityName = "Unknown City";
                }
            }
        }
        xhr.open("GET", url);
        xhr.send();
    }

    FileView {
        id: locFile
        path: root.locFilePath
        onLoaded: {
            let loc = text().trim();
            if (loc && loc.includes(",")) {
                root.weatherLocation = loc;
                root.fetchCityName(loc);
                root.updateWeather();
            }
        }
    }

    function saveLocation(loc) {
        if (!loc || !loc.includes(",")) return;
        let cleanLoc = loc.replace(/[^0-9.,-]/g, "");
        if (!cleanLoc.includes(",")) return;

        locFile.setText(cleanLoc);
        
        root.weatherLocation = cleanLoc;
        root.fetchCityName(cleanLoc);
        root.updateWeather();
    }

    function getWeatherDescription(code) {
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
        };
        return descriptions[code] || "unknown";
    }

    function updateWeather() {
        let loc = root.weatherLocation;
        if (!loc || loc === "") return;

        let lat, lon;
        if (loc.includes(",")) {
            [lat, lon] = loc.split(",");
        } else {
            lat = "51.5074"; lon = "-0.1278";
        }

        let url = `https://api.open-meteo.com/v1/forecast?latitude=${lat.trim()}&longitude=${lon.trim()}&current=temperature_2m,weather_code&timezone=auto`;
        
        try {
            let xhr = new XMLHttpRequest();
            xhr.onreadystatechange = function() {
                if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                    try {
                        let data = JSON.parse(xhr.responseText);
                        if (data && data.current) {
                            let code = data.current.weather_code;
                            root.weatherCondition = getWeatherCondition(code);
                            root.weatherDescription = getWeatherDescription(code);
                            root.weatherTemp = data.current.temperature_2m;
                            
                            let iconMap = { "Clear": "01d", "Clouds": "03d", "Rain": "10d", "Snow": "13d", "Thunderstorm": "11d" };
                            let iconCode = iconMap[root.weatherCondition] || "01d";
                            root.weatherIconUrl = `https://openweathermap.org/img/wn/${iconCode}@2x.png`;
                        }
                    } catch (e) {
                    }
                }
            }
            xhr.open("GET", url);
            xhr.send();
        } catch (e) {
        }
    }

    Timer { 
        interval: FrameConfig.weatherUpdateInterval 
        running: true 
        repeat: true 
        triggeredOnStart: false
        onTriggered: root.updateWeather() 
    }
}
