import QtQuick
import QtQuick.Layouts
import qs.core
import qs.ui.shared

ColumnLayout {
    id: root

    spacing: 10
    Layout.fillWidth: true

    RowLayout {
        Layout.fillWidth: true
        
        ColumnLayout {
            spacing: 2
            Layout.fillWidth: true

            StyledLabel {
                text: {
                    return WeatherManager.currentCityName || "Detecting Location..."
                }
                type: "heading"
                font.pixelSize: 24
            }

            StyledLabel {
                text: {
                    return Qt.formatDateTime(new Date(), "dddd, MMMM d")
                }
                type: "body"
                opacity: 0.6
            }
        }

        Item {
            Layout.fillWidth: true
        }
    }

    StyledCard {
        Layout.fillWidth: true
        Layout.preferredHeight: 180
        backgroundColor: Qt.rgba(1, 1, 1, 0.03)

        RowLayout {
            anchors.fill: parent
            anchors.margins: 25
            spacing: 20

            ColumnLayout {
                spacing: 0
                Layout.fillWidth: true

                RowLayout {
                    spacing: 5
                    
                    StyledLabel {
                        text: {
                            if (isNaN(WeatherManager.currentTemperature)) return "--"
                            return Math.round(WeatherManager.currentTemperature)
                        }
                        font.pixelSize: 72
                        font.weight: Font.Black
                    }

                    StyledLabel {
                        text: "°"
                        font.pixelSize: 48
                        font.weight: Font.Light
                        opacity: 0.5
                        Layout.alignment: Qt.AlignTop
                        Layout.topMargin: 10
                    }
                }

                StyledLabel {
                    text: {
                        let desc = WeatherManager.currentConditionDescription || ""
                        return desc.charAt(0).toUpperCase() + desc.slice(1)
                    }
                    type: "title"
                    font.pixelSize: 18
                    opacity: 0.8
                }

                StyledLabel {
                    text: {
                        if (isNaN(WeatherManager.feelsLike)) return ""
                        return "Feels like " + Math.round(WeatherManager.feelsLike) + "°"
                    }
                    type: "caption"
                    opacity: 0.5
                }
            }

            Text {
                text: {
                    return WeatherManager.mapWeatherCodeToIcon(WeatherManager.currentWeatherCode)
                }
                font.pixelSize: 84
                color: ThemeManager.accentColor
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }
}
