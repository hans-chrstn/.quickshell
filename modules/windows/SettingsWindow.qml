import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.services
import qs.components
import qs.modules.windows

PanelWindow {
    id: root
    
    visible: false
    color: "transparent"
    
    anchors {
        left: true; right: true; top: true; bottom: true
    }
    
    exclusionMode: ExclusionMode.Ignore
    focusable: visible

    Rectangle {
        anchors.fill: parent
        color: ThemeService.shadowMain
        opacity: root.visible ? 0.4 : 0
        Behavior on opacity { NumberAnimation { duration: 400 } }
        
        MouseArea {
            anchors.fill: parent
            onClicked: ViewService.closeWindow("settings")
        }
    }

    ClippingRectangle {
        id: windowFrame
        width: 850; height: 550
        anchors.centerIn: parent
        radius: 28
        color: ThemeService.backgroundMain
        border.color: ThemeService.outlineMain
        border.width: 1
        opacity: root.visible ? 1.0 : 0
        scale: root.visible ? 1.0 : 0.95
        
        Behavior on opacity { NumberAnimation { duration: 300 } }
        Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }
        
        MouseArea {
            anchors.fill: parent
            z: -1
            onPressed: (mouse) => mouse.accepted = true
        }

        RowLayout {
            anchors.fill: parent
            spacing: 0

            SettingsSidebar {
                id: sidebar
                Layout.fillHeight: true
            }

            Item {
                Layout.fillWidth: true; Layout.fillHeight: true
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 40
                    spacing: 24

                    Text {
                        text: ThemeService.settingsStructure[sidebar.currentIndex].category
                        color: ThemeService.backgroundContent
                        font.pixelSize: 32; font.weight: Font.Bold
                    }

                    ListView {
                        id: settingsList
                        Layout.fillWidth: true; Layout.fillHeight: true
                        model: ThemeService.settingsStructure[sidebar.currentIndex].items
                        clip: true
                        spacing: 20
                        interactive: true
                        boundsBehavior: Flickable.StopAtBounds
                        footer: Item { height: 40 }
                        
                        Behavior on contentY { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }

                        delegate: SettingsItemDelegate {
                            width: settingsList.width
                            itemData: modelData
                        }
                    }
                }
            }
        }
    }
}
