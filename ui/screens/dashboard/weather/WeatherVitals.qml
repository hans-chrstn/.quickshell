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
            id: headerCol
            spacing: 2
            Layout.fillWidth: true

            property bool isEditingLocation: false

            RowLayout {
                spacing: 8
                visible: !headerCol.isEditingLocation
                
                StyledLabel {
                    text: {
                        return WeatherManager.currentCityName || "Detecting Location..."
                    }
                    type: "heading"
                    font.pixelSize: 24
                    opacity: locationHover.hovered ? 0.7 : 1.0
                }
                
                StyledLabel {
                    text: "✎"
                    font.pixelSize: 18
                    opacity: locationHover.hovered ? 0.8 : 0.2
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }

                TapHandler {
                    onTapped: {
                        headerCol.isEditingLocation = true
                        locationInput.text = ""
                        locationInput.forceActiveFocus()
                    }
                }
                HoverHandler {
                    id: locationHover
                    cursorShape: Qt.PointingHandCursor
                }
            }

            Rectangle {
                Layout.alignment: Qt.AlignLeft
                width: 200
                height: 32
                visible: headerCol.isEditingLocation
                radius: ThemeManager.radiusSmall
                color: ThemeManager.surfaceStrongColor
                border.color: ThemeManager.outlineVariantColor
                border.width: 1

                TextInput {
                    id: locationInput
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    verticalAlignment: TextInput.AlignVCenter
                    color: ThemeManager.contentOnBackgroundColor
                    font.family: ThemeManager.fontFamily
                    font.pixelSize: 16
                    selectByMouse: true
                    
                    StyledLabel {
                        text: "e.g. 40.71,-74.00"
                        opacity: 0.3
                        visible: !parent.text
                        anchors.verticalCenter: parent.verticalCenter
                        type: "body"
                    }

                    onAccepted: {
                        if (text.trim() !== "") {
                            WeatherManager.updateLocation(text.trim())
                        }
                        headerCol.isEditingLocation = false
                    }
                    Keys.onEscapePressed: headerCol.isEditingLocation = false
                    
                    onActiveFocusChanged: {
                        if (!activeFocus) {
                            headerCol.isEditingLocation = false
                        }
                    }
                }
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
