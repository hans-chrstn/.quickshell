import QtQuick
import QtQuick.Layouts
import qs.services

RowLayout {
    id: root
    Layout.fillWidth: true
    spacing: 12
    
    property string pageType: "wifi"
    
    readonly property bool isEnabled: pageType === "wifi" ? WifiService.wifiEnabled : BluetoothService.bluetoothEnabled

    Text { 
        text: root.pageType.toUpperCase() + " POWER"
        color: ThemeService.backgroundContent; font.pixelSize: 11; font.weight: Font.Black; opacity: 0.6 
    }
    
    Item { Layout.fillWidth: true }

    Rectangle {
        width: 120; height: 40; radius: 20
        color: ThemeService.surfaceVariantStrong
        visible: pageType === "bluetooth" && root.isEnabled
        
        Text {
            anchors.centerIn: parent
            text: BluetoothService.isScanning ? "SCANNING..." : "SCAN FOR DEVICES"
            color: ThemeService.backgroundContent
            font.pixelSize: 9; font.weight: Font.Black
        }
        
        TapHandler {
            onTapped: BluetoothService.startScan()
        }
        HoverHandler { cursorShape: Qt.PointingHandCursor }
    }
    
    Rectangle {
        width: 100; height: 40; radius: 20
        color: root.isEnabled ? ThemeService.accentColor : ThemeService.backgroundContent
        opacity: root.isEnabled ? 1.0 : 0.1
        
        Text {
            anchors.centerIn: parent
            text: root.isEnabled ? "ENABLED" : "DISABLED"
            color: root.isEnabled ? ThemeService.primaryContent : ThemeService.backgroundContent
            font.pixelSize: 9; font.weight: Font.Black
        }
        
        TapHandler {
            onTapped: {
                if (root.pageType === "wifi") WifiService.toggleWifi()
                else BluetoothService.toggleBluetooth()
            }
        }
        HoverHandler { id: hToggle; cursorShape: Qt.PointingHandCursor }
    }
}
