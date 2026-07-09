import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.core
import qs.ui.shared
import qs.ui.screens.dashboard.weather

ColumnLayout {
    id: root

    property bool active: false
    
    anchors.fill: parent
    anchors.margins: 30
    spacing: 25

    WeatherVitals {
        id: weatherVitals
        Layout.fillWidth: true
    }

    WeatherHourly {
        id: weatherHourly
        Layout.fillWidth: true
    }

    WeatherStats {
        id: weatherStats
        Layout.fillWidth: true
    }

    WeatherForecast {
        id: weatherForecast
        Layout.fillWidth: true
        Layout.fillHeight: true
    }
}
