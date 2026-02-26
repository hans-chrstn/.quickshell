import QtQuick
import QtQuick.Layouts
import qs.core
import qs.ui.shared

RowLayout {
    id: root
    
    Layout.fillWidth: true
    spacing: 12
    
    property string panelType: "wifi"
    
    readonly property bool isComponentEnabled: panelType === "wifi" ? WifiManager.isEnabled : BluetoothManager.isEnabled

    Text { 
        text: root.panelType.toUpperCase() + " POWER"
        color: ThemeManager.contentOnBackgroundColor
        font.pixelSize: 11
        font.weight: Font.Black
        opacity: 0.6 
    }
    
    Item { Layout.fillWidth: true }

    BaseButton {
        width: 120
        height: 40
        visible: panelType === "bluetooth" && root.isComponentEnabled
        onClicked: BluetoothManager.startScan()
        
        Rectangle {
            anchors.fill: parent
            radius: 20
            color: ThemeManager.surfaceVariantStrongColor
            
            Text {
                anchors.centerIn: parent
                text: BluetoothManager.isScanning ? "SCANNING..." : "SCAN FOR DEVICES"
                color: ThemeManager.contentOnBackgroundColor
                font.pixelSize: 9
                font.weight: Font.Black
            }
        }
    }
    
    BaseButton {
        width: 100
        height: 40
        onClicked: {
            if (root.panelType === "wifi") {
                WifiManager.togglePower()
            } else {
                BluetoothManager.togglePower()
            }
        }
        
        Rectangle {
            id: toggleButton
            anchors.fill: parent
            radius: 20
            color: root.isComponentEnabled ? ThemeManager.accentColor : ThemeManager.contentOnBackgroundColor
            opacity: root.isComponentEnabled ? 1.0 : 0.1
            Behavior on color { ColorAnimation { duration: 200 } }
            Behavior on opacity { NumberAnimation { duration: 200 } }
            
            Text {
                anchors.centerIn: parent
                text: root.isComponentEnabled ? "ENABLED" : "DISABLED"
                color: root.isComponentEnabled ? ThemeManager.contentPrimaryColor : ThemeManager.contentOnBackgroundColor
                font.pixelSize: 9
                font.weight: Font.Black
            }
        }
    }
}
