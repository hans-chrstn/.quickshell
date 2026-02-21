import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.components
import qs.services
import qs.modules.windows

Item {
    id: root
    anchors.fill: parent
    
    RowLayout {
        id: mainView
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 0
        spacing: 24

        GridLayout {
            columns: 2
            rowSpacing: 12
            columnSpacing: 12
            Layout.alignment: Qt.AlignVCenter

            ExpandableControlTile { 
                icon: "󰖩"; label: "Wifi"
                active: !!SystemControl.wifiEnabled
                enabled: SystemControl.hasWifi
                onClicked: SystemControl.toggleWifi()
                onLongPressed: {
                    controlPanelWin.activePage = "wifi"
                    controlPanelWin.visible = true
                }
            }
            ExpandableControlTile { 
                icon: "󰂯"; label: "Bluetooth"
                active: !!SystemControl.bluetoothEnabled
                enabled: SystemControl.hasBluetooth
                onClicked: SystemControl.toggleBluetooth()
                onLongPressed: {
                    controlPanelWin.activePage = "bluetooth"
                    controlPanelWin.visible = true
                }
            }
            ControlTile { 
                icon: "󰀝"; active: !!SystemControl.airplaneMode
                enabled: SystemControl.hasWifi
                onClicked: SystemControl.toggleAirplane()
            }
            ControlTile { 
                icon: "󰂛"; active: !!SystemControl.dndActive
                enabled: SystemControl.hasDunst
                onClicked: SystemControl.toggleDND()
            }
        }

        Rectangle {
            width: 1; height: 120
            color: "white"; opacity: 0.05
            Layout.alignment: Qt.AlignVCenter
        }

        ColumnLayout {
            spacing: 12
            Layout.alignment: Qt.AlignVCenter

            ColumnLayout {
                spacing: 4
                Text { text: "BRIGHTNESS"; color: "white"; font.pixelSize: 8; font.weight: Font.Black; font.letterSpacing: 1.5; opacity: 0.3; Layout.leftMargin: 4 }
                ControlSlider { 
                    width: 180; height: 28
                    enabled: SystemControl.hasBrightness
                    value: SystemControl.brightness
                    icon: "󰃠"; barColor: "#FFCC00"
                    onMoved: (v) => SystemControl.setBrightness(v)
                }
            }

            ColumnLayout {
                spacing: 4
                Text { text: "VOLUME"; color: "white"; font.pixelSize: 8; font.weight: Font.Black; font.letterSpacing: 1.5; opacity: 0.3; Layout.leftMargin: 4 }
                ControlSlider { 
                    width: 180; height: 28
                    enabled: SystemControl.hasAudio
                    value: SystemControl.volume
                    icon: SystemControl.muted ? "󰝟" : "󰕾"; barColor: "white"
                    onMoved: (v) => SystemControl.setVolume(v)
                }
            }
            
            Text {
                text: "OPEN SETTINGS 󰒓"
                color: FrameConfig.accentColor; font.pixelSize: 9; font.weight: Font.Black; font.letterSpacing: 1
                Layout.alignment: Qt.AlignRight
                Layout.topMargin: 4
                Layout.bottomMargin: 12
                opacity: hhSet.hovered ? 1.0 : 0.6
                Behavior on opacity { NumberAnimation { duration: 200 } }
                TapHandler { onTapped: settingsWin.visible = true }
                HoverHandler { id: hhSet; cursorShape: Qt.PointingHandCursor }
            }
        }
    }

    SettingsWindow {
        id: settingsWin
    }
}
