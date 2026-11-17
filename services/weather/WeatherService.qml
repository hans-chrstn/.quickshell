pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "WeatherConditions.js" as Conditions

Singleton {
    id: root

    property var consumers: ({})
    property real latitude: Number(Quickshell.env("QS_WEATHER_LAT"))
    property real longitude: Number(Quickshell.env("QS_WEATHER_LON"))
    property bool coordinatesReady: String(Quickshell.env("QS_WEATHER_LAT") || "").length > 0 && String(Quickshell.env("QS_WEATHER_LON") || "").length > 0 && Number.isFinite(latitude) && Number.isFinite(longitude)
    property var current: null
    property string error: ""
    property double lastUpdatedMs: 0
    property double lastAttemptMs: 0
    readonly property int consumerCount: Object.keys(consumers).length
    readonly property bool active: consumerCount > 0
    readonly property bool available: current !== null
    readonly property string kind: available ? Conditions.kind(current.code) : "unknown"
    readonly property string glyph: available ? Conditions.glyph(current.code, current.isDay) : ""
    readonly property string description: available ? Conditions.description(current.code) : "Weather unavailable"
    readonly property string temperature: available ? Math.round(current.temperatureC) + "°" : ""

    function setConsumer(id, enabled) {
        const key = String(id || "").trim();
        if (key.length === 0)
            return false;
        const next = Object.assign({}, consumers);
        if (enabled)
            next[key] = true;
        else
            delete next[key];
        consumers = next;
        if (active && Date.now() - lastUpdatedMs > 45 * 60 * 1000)
            refresh();
        return true;
    }

    function refresh() {
        if (!active || geoProcess.running || weatherProcess.running || Date.now() - lastAttemptMs < 15 * 60 * 1000)
            return;
        lastAttemptMs = Date.now();
        if (!coordinatesReady) {
            geoProcess.command = ["curl", "--silent", "--show-error", "--fail", "--max-time", "8", "https://ipwho.is/"];
            geoProcess.running = true;
            return;
        }
        const url = "https://api.open-meteo.com/v1/forecast?latitude=" + latitude.toFixed(4) + "&longitude=" + longitude.toFixed(4) + "&current=temperature_2m,weather_code,is_day&forecast_days=1";
        weatherProcess.command = ["curl", "--silent", "--show-error", "--fail", "--max-time", "8", url];
        weatherProcess.running = true;
    }

    Timer {
        interval: 60 * 60 * 1000
        repeat: true
        running: root.active
        onTriggered: root.refresh()
    }

    Process {
        id: geoProcess
        property string output: ""
        stdout: StdioCollector {
            onStreamFinished: geoProcess.output = text
        }
        onExited: exitCode => {
            if (exitCode !== 0) {
                root.error = "Location unavailable";
                return;
            }
            try {
                const data = JSON.parse(output);
                const lat = Number(data.latitude);
                const lon = Number(data.longitude);
                if (data.success !== true || !Number.isFinite(lat) || !Number.isFinite(lon))
                    throw new Error("Invalid location");
                root.latitude = lat;
                root.longitude = lon;
                root.coordinatesReady = true;
                root.lastAttemptMs = 0;
                root.refresh();
            } catch (failure) {
                root.error = "Location unavailable";
            }
        }
    }

    Process {
        id: weatherProcess
        property string output: ""
        stdout: StdioCollector {
            onStreamFinished: weatherProcess.output = text
        }
        onExited: exitCode => {
            if (exitCode !== 0) {
                root.error = "Weather unavailable";
                return;
            }
            try {
                const parsed = Conditions.currentFromJson(JSON.parse(output));
                if (!parsed)
                    throw new Error("Invalid weather");
                root.current = parsed;
                root.lastUpdatedMs = Date.now();
                root.error = "";
            } catch (failure) {
                root.error = "Weather unavailable";
            }
        }
    }
}
