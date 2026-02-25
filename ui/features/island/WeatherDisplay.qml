import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.core

Item {
    id: root
    
    anchors.fill: parent

    property bool isInputModeActive: false

    onVisibleChanged: {
        if (!visible) {
            isInputModeActive = false
        }
    }

    ClippingRectangle {
        id: displayContainer
        anchors.centerIn: parent
        width: parent.width * 0.94
        height: parent.height * 0.8
        radius: 24
        color: ThemeManager.backgroundPrimaryColor
        border.width: 1
        border.color: ThemeManager.outlinePrimaryColor
        
        Image {
            id: backgroundWeatherImage
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            source: WeatherManager.currentBackgroundUrl
            opacity: 0.45
            visible: !root.isInputModeActive
            
            Behavior on source { 
                PropertyAnimation { 
                    duration: 1000 
                } 
            }
        }

        Rectangle {
            anchors.fill: parent
            visible: !root.isInputModeActive
            
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { 
                    position: 1.0
                    color: Qt.rgba(ThemeManager.shadowPrimaryColor.r, ThemeManager.shadowPrimaryColor.g, ThemeManager.shadowPrimaryColor.b, 0.6) 
                }
            }
        }

        Loader {
            anchors.centerIn: parent
            sourceComponent: root.isInputModeActive ? locationInputComponent : weatherCardComponent
        }

        Component {
            id: weatherCardComponent
            WeatherInfoCard {
                onInputRequested: root.isInputModeActive = true
            }
        }

        Component {
            id: locationInputComponent
            WeatherLocationInput {
                onInteractionFinished: root.isInputModeActive = false
            }
        }
    }
}
