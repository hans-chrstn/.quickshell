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

    StyledLabel { 
        text: root.panelType.toUpperCase() + " POWER"
        type: "caption"
        font.weight: Font.Black
        opacity: 0.6 
    }
    
    Item { Layout.fillWidth: true }

    BaseButton {
        id: scanBtn
        width: 120
        height: 40
        visible: panelType === "bluetooth" && root.isComponentEnabled
        onClicked: BluetoothManager.startScan()
        
        Rectangle {
            anchors.fill: parent
            radius: 20
            color: ThemeManager.surfaceVariantStrongColor
            scale: scanBtn.isHovered ? 1.05 : 1.0
            Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }
            
            StyledLabel {
                anchors.centerIn: parent
                text: BluetoothManager.isScanning ? "SCANNING..." : "SCAN FOR DEVICES"
                type: "caption"
                font.weight: Font.Black
                font.pixelSize: 9
            }
        }
    }
    
    BaseButton {
        id: pwrToggleBtn
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
            color: root.isComponentEnabled ? ThemeManager.accentColor : ThemeManager.surfacePrimaryColor
            opacity: root.isComponentEnabled ? 1.0 : (pwrToggleBtn.isHovered ? 0.8 : 0.5)
            scale: pwrToggleBtn.isHovered ? 1.05 : 1.0
            Behavior on color { ColorAnimation { duration: 200 } }
            Behavior on opacity { NumberAnimation { duration: 200 } }
            Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }
            
            StyledLabel {
                anchors.centerIn: parent
                text: root.isComponentEnabled ? "ENABLED" : "DISABLED"
                type: "caption"
                font.weight: Font.Black
                font.pixelSize: 9
                customColor: root.isComponentEnabled ? ThemeManager.contentPrimaryColor : ThemeManager.contentOnBackgroundColor
            }
        }
    }
}
