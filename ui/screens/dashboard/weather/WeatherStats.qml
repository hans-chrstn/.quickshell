import QtQuick
import QtQuick.Layouts
import qs.core
import qs.ui.shared

GridLayout {
    id: root

    columns: 2
    rows: 2
    columnSpacing: 15
    rowSpacing: 15
    Layout.fillWidth: true

    Repeater {
        model: [
            { 
                label: "Humidity", 
                value: isNaN(WeatherManager.humidity) 
                    ? "--%" 
                    : Math.round(WeatherManager.humidity) + "%", 
                icon: "󰖑" 
            },
            { 
                label: "Wind Speed", 
                value: isNaN(WeatherManager.windSpeed) 
                    ? "-- km/h" 
                    : Math.round(WeatherManager.windSpeed) + " km/h", 
                icon: "󰖝" 
            },
            { 
                label: "UV Index", 
                value: isNaN(WeatherManager.uvIndex) 
                    ? "--" 
                    : Math.round(WeatherManager.uvIndex), 
                icon: "󰖙" 
            },
            { 
                label: "Feels Like", 
                value: isNaN(WeatherManager.feelsLike) 
                    ? "--°" 
                    : Math.round(WeatherManager.feelsLike) + "°", 
                icon: "󰖕" 
            }
        ]

        delegate: StyledCard {
            Layout.fillWidth: true
            Layout.preferredHeight: 80
            backgroundColor: Qt.rgba(1, 1, 1, 0.02)

            RowLayout {
                anchors.fill: parent
                anchors.margins: 15
                spacing: 12

                Text {
                    text: modelData.icon
                    font.pixelSize: 24
                    color: ThemeManager.accentColor
                    opacity: 0.8
                }

                ColumnLayout {
                    spacing: 0
                    Layout.fillWidth: true

                    StyledLabel {
                        text: modelData.label
                        type: "caption"
                        opacity: 0.5
                    }

                    StyledLabel {
                        text: String(modelData.value || "")
                        type: "body"
                        font.weight: Font.Bold
                        font.pixelSize: 16
                    }
                }
            }
        }
    }
}
