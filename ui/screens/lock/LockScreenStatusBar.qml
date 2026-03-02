import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.core

Item {
    id: root
    
    implicitHeight: 60

    RowLayout {
        id: weatherStatusLayout
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: 15
        visible: !isNaN(WeatherManager.currentTemperature)

        Image {
            id: weatherStatusIcon
            source: WeatherManager.currentWeatherIconUrl
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
        }
        
        ColumnLayout {
            spacing: 0
            
            Text { 
                id: temperatureLabel
                text: WeatherManager.currentTemperature.toFixed(1) + "°"
                color: ThemeManager.contentOnBackgroundColor
                font.pixelSize: 18
                font.weight: Font.Bold 
            }
            
            Text { 
                id: cityLabel
                text: WeatherManager.currentCityName.toUpperCase()
                color: ThemeManager.contentOnBackgroundColor
                font.pixelSize: 10
                opacity: 0.6
                font.weight: Font.Black
                font.letterSpacing: 1
            }
        }
    }

    RowLayout {
        id: systemStatusLayout
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 25
        
        RowLayout {
            id: connectivityLayout
            spacing: 15
            
            Text { 
                id: wifiStatusIcon
                text: NetworkManager.statusIcon
                color: ThemeManager.contentOnBackgroundColor
                font.pixelSize: 20
                opacity: 0.8 
            }
            
            Text { 
                id: bluetoothStatusIcon
                text: BluetoothManager.isEnabled ? ThemeManager.iconBluetooth : ThemeManager.iconBluetoothOff
                color: ThemeManager.contentOnBackgroundColor
                font.pixelSize: 20
                opacity: 0.8 
            }
            
            RowLayout {
                id: batteryStatusLayout
                spacing: 6
                visible: BatteryManager.isUPowerAvailable && !!BatteryManager.mainDevice
                
                Text { 
                    id: batteryPercentageLabel
                    text: (BatteryManager.mainDevice ? (BatteryManager.mainDevice.percentage * 100).toFixed(0) : "0") + "%"
                    color: ThemeManager.contentOnBackgroundColor
                    font.pixelSize: 16
                    font.weight: Font.Medium
                    opacity: 0.8 
                }
                
                Text { 
                    id: batteryIcon
                    text: BatteryManager.mainDevice ? (BatteryManager.mainDevice.state === 1 ? ThemeManager.iconCharging : ThemeManager.iconBattery) : ThemeManager.iconBattery
                    color: BatteryManager.mainDevice && BatteryManager.mainDevice.percentage < 0.2 
                        ? ThemeManager.dangerColor 
                        : ThemeManager.contentOnBackgroundColor
                    font.pixelSize: 22 
                }
            }
        }
    }
}
