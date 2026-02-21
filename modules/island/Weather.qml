import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import qs.config

Item {
    id: root
    anchors.fill: parent

    property bool inputMode: false
    property string weatherLocation: ""
    property string cityName: ""
    property string weatherCondition: ""
    property string weatherDescription: ""
    property real weatherTemp: NaN
    property string weatherIconUrl: ""

    onInputModeChanged: {
        if (inputMode) {
            locInput.forceActiveFocus();
        } else {
            locInput.focus = false;
        }
    }

    onVisibleChanged: {
        if (!visible) {
            root.inputMode = false;
            locInput.focus = false;
        }
    }

    readonly property string cacheDir: Quickshell.cachePath("weather_images")
    readonly property string locFilePath: Quickshell.cachePath("location")

    readonly property var bgMap: {
        "Clear": "https://images.unsplash.com/photo-1504608524841-42fe6f032b4b?q=80&w=1000&auto=format&fit=crop",
        "Clouds": "https://images.unsplash.com/photo-1534088568595-a066f410bcda?q=80&w=1000&auto=format&fit=crop",
        "Rain": "https://images.unsplash.com/photo-1534274988757-a28bf1a57c17?q=80&w=1000&auto=format&fit=crop",
        "Snow": "https://images.unsplash.com/photo-1491002052546-bf38f186af56?q=80&w=1000&auto=format&fit=crop",
        "Thunderstorm": "https://images.unsplash.com/photo-1605727216801-e27ce1d0cc28?q=80&w=1000&auto=format&fit=crop"
    }

    property string currentBgSource: bgMap["Clear"]

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
                root.inputMode = false;
            } else {
                root.inputMode = true;
            }
        }
        onLoadFailed: root.inputMode = true
    }

    function saveLocation(loc) {
        if (!loc || !loc.includes(",")) return;
        let cleanLoc = loc.replace(/[^0-9.,-]/g, "");
        if (!cleanLoc.includes(",")) return;

        locFile.setText(cleanLoc);
        
        root.weatherLocation = cleanLoc;
        root.fetchCityName(cleanLoc);
        root.inputMode = false;
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

    ClippingRectangle {
        id: card
        anchors.centerIn: parent
        width: parent.width * 0.94
        height: parent.height * 0.8
        radius: 24
        color: FrameConfig.color
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.15)
        
        Image {
            id: bgImage
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            source: root.currentBgSource
            opacity: 0.45
            visible: !root.inputMode
            Behavior on source { PropertyAnimation { duration: 1000 } }
        }

        Rectangle {
            anchors.fill: parent
            visible: !root.inputMode
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.6) }
            }
        }

        ColumnLayout {
            anchors.centerIn: parent
            visible: root.inputMode
            spacing: 10
            Text {
                text: "ENTER COORDINATES"
                color: "white"
                font.pixelSize: 10
                font.weight: Font.Bold
                Layout.alignment: Qt.AlignHCenter
                opacity: 0.6
            }

            Rectangle {
                width: 200; height: 36; radius: 18
                color: "white"; opacity: locInput.activeFocus ? 0.2 : 0.1
                Layout.alignment: Qt.AlignHCenter
                border.color: "white"
                border.width: locInput.activeFocus ? 1 : 0
                
                TextInput {
                    id: locInput
                    anchors.fill: parent
                    anchors.leftMargin: 15; anchors.rightMargin: 15
                    verticalAlignment: TextInput.AlignVCenter
                    horizontalAlignment: TextInput.AlignHCenter
                    color: "white"
                    font.pixelSize: 14
                    selectByMouse: true
                    onAccepted: root.saveLocation(text)
                    Keys.onEscapePressed: root.inputMode = false
                    Text {
                        text: "lat,lon"
                        color: "white"; opacity: 0.3
                        visible: !parent.text && !parent.activeFocus
                        anchors.centerIn: parent
                    }
                }
                
                TapHandler {
                    onTapped: locInput.forceActiveFocus()
                }

                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: "✕"
                    color: "white"
                    opacity: 0.5
                    font.pixelSize: 12
                    TapHandler {
                        onTapped: root.inputMode = false
                    }
                }
            }
            Text {
                text: "PRESS ENTER TO SAVE"
                color: "white"; opacity: 0.3; font.pixelSize: 8
                Layout.alignment: Qt.AlignHCenter
            }
        }

        RowLayout {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 0
            spacing: 20
            visible: !root.inputMode
            ColumnLayout {
                spacing: -4
                Text {
                    text: isNaN(root.weatherTemp) ? "--°" : Math.round(root.weatherTemp) + "°"
                    color: "white"; font.pixelSize: 42; font.weight: Font.DemiBold; font.letterSpacing: -1
                }
                Text {
                    text: (root.cityName || root.weatherLocation || "NO LOCATION").toUpperCase()
                    color: FrameConfig.secondaryTextColor; opacity: 0.8; font.pixelSize: 9; font.weight: Font.Bold; font.letterSpacing: 1.5
                    TapHandler { onTapped: root.inputMode = true }
                }
            }
            Rectangle { width: 1; height: 30; color: "white"; opacity: 0.1 }
            RowLayout {
                spacing: 8
                Image { 
                    source: root.weatherIconUrl || ""; width: 40; height: 40; fillMode: Image.PreserveAspectFit
                    visible: !!root.weatherIconUrl 
                }
                ColumnLayout {
                    spacing: 1
                    Text {
                        text: (root.weatherCondition || "LOADING").toUpperCase()
                        color: "white"; font.pixelSize: 11; font.weight: Font.Bold; font.letterSpacing: 0.5
                    }
                    Text {
                        text: root.weatherDescription || "fetching..."
                        color: FrameConfig.secondaryTextColor; opacity: 0.8; font.pixelSize: 9; font.italic: true
                    }
                }
            }
        }
    }
}
