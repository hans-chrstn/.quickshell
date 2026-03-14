import QtQuick
import QtQuick.Layouts
import qs.core
import qs.ui.shared

ColumnLayout {
    id: root

    spacing: 12
    Layout.fillWidth: true
    Layout.fillHeight: true

    StyledLabel {
        text: "7-Day Forecast"
        type: "title"
        font.pixelSize: 16
        opacity: 0.7
    }

    StyledCard {
        Layout.fillWidth: true
        Layout.fillHeight: true
        backgroundColor: Qt.rgba(1, 1, 1, 0.02)

        ListView {
            id: forecastList
            anchors.fill: parent
            anchors.margins: 10
            model: WeatherManager.forecastStore
            spacing: 0
            clip: true
            interactive: true

            delegate: ColumnLayout {
                width: forecastList.width
                height: 50
                spacing: 0

                RowLayout {
                    Layout.fillWidth: true
                    Layout.margins: 10
                    spacing: 15

                    StyledLabel {
                        text: {
                            return String(model.day || "")
                        }
                        type: "body"
                        font.weight: Font.DemiBold
                        Layout.preferredWidth: 80
                    }

                    Text {
                        text: {
                            return String(model.icon || "")
                        }
                        font.pixelSize: 20
                        color: ThemeManager.accentColor
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    RowLayout {
                        spacing: 12
                        
                        StyledLabel {
                            text: {
                                return Math.round(model.high || 0) + "°"
                            }
                            type: "body"
                            font.weight: Font.Bold
                        }

                        StyledLabel {
                            text: {
                                return Math.round(model.low || 0) + "°"
                            }
                            type: "body"
                            opacity: 0.4
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: ThemeManager.outlineVariantColor
                    opacity: 0.1
                    visible: {
                        return index < forecastList.count - 1
                    }
                }
            }
        }
    }
}
