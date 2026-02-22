import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.config
import qs.components
import qs.services

Item {
    id: root
    anchors.fill: parent

    property bool inputMode: false

    onVisibleChanged: if (!visible) inputMode = false

    ClippingRectangle {
        id: container
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
            source: WeatherService.currentBgSource
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

        Loader {
            anchors.centerIn: parent
            sourceComponent: root.inputMode ? inputComp : cardComp
        }

        Component {
            id: cardComp
            WeatherCard {
                onRequestInput: root.inputMode = true
            }
        }

        Component {
            id: inputComp
            WeatherInput {
                onFinished: root.inputMode = false
            }
        }
    }
}
