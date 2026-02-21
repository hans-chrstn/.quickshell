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
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -10
        spacing: 32

        ColumnLayout {
            spacing: 10
            Layout.alignment: Qt.AlignVCenter

            RowLayout {
                spacing: 10
                ControlTile { 
                    width: FrameConfig.controlCenterTileSize; height: FrameConfig.controlCenterTileSize; radius: FrameConfig.controlCenterTileRadius
                    icon: "󰖩"; active: !!SystemControl.wifiEnabled
                    enabled: SystemControl.hasWifi
                    onClicked: SystemControl.toggleWifi()
                }
                ControlTile { 
                    width: FrameConfig.controlCenterTileSize; height: FrameConfig.controlCenterTileSize; radius: FrameConfig.controlCenterTileRadius
                    icon: "󰂯"; active: true; activeColor: "#007AFF"
                    enabled: false
                }
            }
            RowLayout {
                spacing: 10
                ControlTile { 
                    width: FrameConfig.controlCenterTileSize; height: FrameConfig.controlCenterTileSize; radius: FrameConfig.controlCenterTileRadius
                    icon: "󰀝"; active: false; enabled: false 
                }
                ControlTile { 
                    width: FrameConfig.controlCenterTileSize; height: FrameConfig.controlCenterTileSize; radius: FrameConfig.controlCenterTileRadius
                    icon: "󰒓"
                    active: settingsWin.visible
                    onClicked: settingsWin.visible = !settingsWin.visible
                }
            }
        }

        Rectangle {
            width: 1; height: 100
            color: "white"; opacity: 0.05
            Layout.alignment: Qt.AlignVCenter
        }

        ColumnLayout {
            spacing: 16
            Layout.alignment: Qt.AlignVCenter

            ColumnLayout {
                spacing: 4
                Text { text: "BRIGHTNESS"; color: "white"; font.pixelSize: 8; font.weight: Font.Black; font.letterSpacing: 1.5; opacity: 0.3; Layout.leftMargin: 4 }
                ControlSlider { 
                    width: FrameConfig.controlCenterSliderWidth; height: FrameConfig.controlCenterSliderHeight
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
                    width: FrameConfig.controlCenterSliderWidth; height: FrameConfig.controlCenterSliderHeight
                    enabled: SystemControl.hasAudio
                    value: SystemControl.volume
                    icon: SystemControl.muted ? "󰝟" : "󰕾"; barColor: "white"
                    onMoved: (v) => SystemControl.setVolume(v)
                }
            }
        }
    }

    SettingsWindow {
        id: settingsWin
    }
}
