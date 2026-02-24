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
        visible: !isNaN(WeatherService.weatherTemp)

        Image {
            source: WeatherService.weatherIconUrl
            Layout.preferredWidth: 40; Layout.preferredHeight: 40
        }
        ColumnLayout {
            spacing: 0
            Text { 
                text: WeatherService.weatherTemp.toFixed(1) + "°"
                color: "white"; font.pixelSize: 18; font.weight: Font.Bold 
            }
            Text { 
                text: WeatherService.cityName.toUpperCase()
                color: "white"; font.pixelSize: 10; opacity: 0.6; font.weight: Font.Black; font.letterSpacing: 1
            }
        }
    }

    RowLayout {
        anchors.right: parent.right
        spacing: 25
        
        RowLayout {
            spacing: 15
            Text { text: WifiService.wifiEnabled ? "󰖩" : "󰖪"; color: "white"; font.pixelSize: 20; opacity: 0.8 }
            Text { text: BluetoothService.bluetoothEnabled ? "󰂯" : "󰂲"; color: "white"; font.pixelSize: 20; opacity: 0.8 }
            
            RowLayout {
                spacing: 6
                visible: BatteryService.hasUPower && !!BatteryService.device
                Text { 
                    text: (BatteryService.device ? (BatteryService.device.percentage * 100).toFixed(0) : "0") + "%"
                    color: "white"; font.pixelSize: 16; font.weight: Font.Medium; opacity: 0.8 
                }
                Text { 
                    text: BatteryService.device ? (BatteryService.device.state === 1 ? "󱐋" : "󰁹") : "󰂄"
                    color: BatteryService.device && BatteryService.device.percentage < 0.2 ? ThemeService.dangerColor : "white"
                    font.pixelSize: 22 
                }
            }
        }
    }
}
