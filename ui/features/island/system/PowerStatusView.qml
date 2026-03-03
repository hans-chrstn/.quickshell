import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.core
import qs.ui.shared

Item {
    id: root
    
    anchors.fill: parent

    readonly property var battery: BatteryManager.mainDevice

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 12

        RowLayout {
            spacing: 24
            Layout.alignment: Qt.AlignHCenter

            ColumnLayout {
                spacing: 4
                Layout.alignment: Qt.AlignVCenter

                StyledLabel {
                    text: root.battery ? (root.battery.percentage * 100).toFixed(0) + "%" : "NO BATTERY"
                    type: "heading"
                    font.pixelSize: 32
                    font.weight: Font.Black
                    Layout.alignment: Qt.AlignHCenter
                }

                StyledLabel {
                    text: root.battery ? (root.battery.state === 1 ? "CHARGING" : "DISCHARGING") : "UNKNOWN"
                    type: "caption"
                    font.weight: Font.Black
                    letterSpacing: 1
                    opacity: 0.4
                    Layout.alignment: Qt.AlignHCenter
                }
            }

            Rectangle {
                width: 1
                Layout.preferredHeight: 40
                color: ThemeManager.contentOnBackgroundColor
                opacity: 0.1
            }

            RowLayout {
                spacing: 16
                Layout.alignment: Qt.AlignVCenter

                BaseButton {
                    width: 40
                    height: 40
                    cornerRadius: 20
                    onClicked: {
                        ViewManager.toggleNetwork()
                    }
                    
                    Rectangle {
                        anchors.fill: parent
                        radius: 20
                        color: ThemeManager.contentOnBackgroundColor
                        opacity: parent.isHovered ? 0.15 : 0.08
                        
                        StyledLabel {
                            anchors.centerIn: parent
                            text: NetworkManager.statusIcon
                            type: "icon"
                            font.pixelSize: 18
                        }
                    }
                }

                BaseButton {
                    width: 40
                    height: 40
                    cornerRadius: 20
                    onClicked: {
                        ViewManager.toggleBluetooth()
                    }
                    
                    Rectangle {
                        anchors.fill: parent
                        radius: 20
                        color: ThemeManager.contentOnBackgroundColor
                        opacity: parent.isHovered ? 0.15 : 0.08
                        
                        StyledLabel {
                            anchors.centerIn: parent
                            text: BluetoothManager.isEnabled ? ThemeManager.iconBluetooth : ThemeManager.iconBluetoothOff
                            type: "icon"
                            font.pixelSize: 18
                        }
                    }
                }
            }
        }
    }
}
