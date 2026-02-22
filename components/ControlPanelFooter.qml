import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services

RowLayout {
    id: root
    Layout.fillWidth: true
    
    property string pageType: "wifi"
    
    readonly property bool isEnabled: pageType === "wifi" ? WifiService.wifiEnabled : BluetoothService.bluetoothEnabled

    Text { 
        text: root.pageType.toUpperCase() + " POWER"
        color: "white"; font.pixelSize: 11; font.weight: Font.Black; opacity: 0.6 
    }
    
    Item { Layout.fillWidth: true }
    
    Rectangle {
        width: 120; height: 40; radius: 20
        color: root.isEnabled ? FrameConfig.accentColor : "#FFFFFF"
        opacity: root.isEnabled ? 1.0 : 0.1
        
        Text {
            anchors.centerIn: parent
            text: root.isEnabled ? "ENABLED" : "DISABLED"
            color: root.isEnabled ? "black" : "white"
            font.pixelSize: 10; font.weight: Font.Black
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
