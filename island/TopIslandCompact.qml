import QtQuick
import QtQuick.Layouts
import qs.components
import qs.core
import qs.services.time
import qs.services.weather

Item {
    id: root

    readonly property string timeText: Qt.formatTime(ClockService.now, "hh:mm")

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 0

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.timeText
            color: Theme.textPrimary
            font.family: Design.fontDisplay
            font.pixelSize: 19
            font.weight: Font.DemiBold
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 4

            IslandGlyph {
                id: weatherIcon
                Layout.preferredWidth: 16
                Layout.preferredHeight: 16
                name: WeatherService.available ? WeatherService.kind === "clear" ? (WeatherService.current?.isDay ? "sun" : "moon") : WeatherService.kind : WeatherService.error.length > 0 ? "weatherUnavailable" : "cloud"
                glyphColor: Theme.textSecondary
                Accessible.role: Accessible.Graphic
                Accessible.name: WeatherService.available ? WeatherService.description : WeatherService.error.length > 0 ? "Weather unavailable" : "Loading weather"
                SequentialAnimation on opacity {
                    running: !WeatherService.available && WeatherService.error.length === 0 && !Design.reducedMotion
                    loops: Animation.Infinite
                    onRunningChanged: if (!running)
                        weatherIcon.opacity = 1
                    NumberAnimation {
                        to: 0.32
                        duration: Design.weatherPulseDuration
                        easing.type: Easing.InOutSine
                    }
                    NumberAnimation {
                        to: 1
                        duration: Design.weatherPulseDuration
                        easing.type: Easing.InOutSine
                    }
                }
            }

            Text {
                visible: WeatherService.available
                text: WeatherService.temperature
                color: Theme.textSecondary
                font.family: Design.fontText
                font.pixelSize: 11
            }
        }
    }
}
