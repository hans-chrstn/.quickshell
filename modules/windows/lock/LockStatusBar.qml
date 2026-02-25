import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services

Item {
    id: root
    height: 60
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.topMargin: 60
    anchors.leftMargin: 60
    anchors.rightMargin: 60

    RowLayout {
        anchors.left: parent.left
        spacing: 15
        visible: !isNaN(WeatherManager.currentTemperature)

        Image {
            source: WeatherManager.currentWeatherIconUrl
            Layout.preferredWidth: 40; Layout.preferredHeight: 40
        }
        ColumnLayout {
            spacing: 0
            Text { 
                text: WeatherManager.currentTemperature.toFixed(1) + "°"
                color: "white"; font.pixelSize: 18; font.weight: Font.Bold 
            }
            Text { 
                text: WeatherManager.currentCityName.toUpperCase()
                color: "white"; font.pixelSize: 10; opacity: 0.6; font.weight: Font.Black; font.letterSpacing: 1
            }
        }
    }

    RowLayout {
        anchors.right: parent.right
        spacing: 25
        
        RowLayout {
            spacing: 15
            Text { text: WifiManager.isEnabled ? "󰖩" : "󰖪"; color: "white"; font.pixelSize: 20; opacity: 0.8 }
            Text { text: BluetoothManager.isEnabled ? "󰂯" : "󰂲"; color: "white"; font.pixelSize: 20; opacity: 0.8 }
            
            RowLayout {
                spacing: 6
                visible: BatteryManager.isUPowerAvailable && !!BatteryManager.mainDevice
                Text { 
                    text: (BatteryManager.mainDevice ? (BatteryManager.mainDevice.percentage * 100).toFixed(0) : "0") + "%"
                    color: "white"; font.pixelSize: 16; font.weight: Font.Medium; opacity: 0.8 
                }
                Text { 
                    text: BatteryManager.mainDevice ? (BatteryManager.mainDevice.state === 1 ? "󱐋" : "󰁹") : "󰂄"
                    color: BatteryManager.mainDevice && BatteryManager.mainDevice.percentage < 0.2 ? ThemeManager.dangerColor : "white"
                    font.pixelSize: 22 
                }
            }
        }
    }
}
