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
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    Shortcut {
        sequence: "Escape"
        enabled: root.visible
        onActivated: ViewManager.closeWindowByType("settings")
    }

    onVisibleChanged: {
        if (visible) {
            Qt.callLater(() => {
                sidebar.forceActiveFocus()
            })
        }
    }

    Rectangle {
        anchors.fill: parent
        color: ThemeManager.shadowPrimaryColor
        opacity: (root.visible && !ViewManager.isSettingsClosing) ? 0.4 : 0
        Behavior on opacity { NumberAnimation { duration: 300 } }
        
        MouseArea {
            anchors.fill: parent
            onClicked: ViewManager.closeWindowByType("settings")
        }
    }

    ClippingRectangle {
        id: windowFrame
        width: 850; height: 550
        anchors.centerIn: parent
        radius: 28
        color: ThemeManager.backgroundPrimaryColor
        border.color: ThemeManager.outlinePrimaryColor
        border.width: 1
        opacity: (root.visible && !ViewManager.isSettingsClosing) ? 1.0 : 0
        scale: (root.visible && !ViewManager.isSettingsClosing) ? 1.0 : 0.95
        
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
                activeFocusOnTab: true
                KeyNavigation.tab: settingsListScope
            }

            FocusScope {
                id: settingsListScope
                Layout.fillWidth: true; Layout.fillHeight: true
                activeFocusOnTab: true
                
                KeyNavigation.tab: sidebar
                
                onActiveFocusChanged: {
                    if (activeFocus) {
                        settingsList.forceActiveFocus()
                    }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 40
                    spacing: 24

                    Text {
                        text: ThemeManager.settingsStructure[sidebar.currentIndex].category
                        color: ThemeManager.contentOnBackgroundColor
                        font.pixelSize: 32; font.weight: Font.Bold
                    }

                    ListView {
                        id: settingsList
                        Layout.fillWidth: true; Layout.fillHeight: true
                        model: ThemeManager.settingsStructure[sidebar.currentIndex].items
                        clip: true
                        spacing: 20
                        interactive: true
                        boundsBehavior: Flickable.StopAtBounds
                        footer: Item { height: 40 }
                        
                        focus: true
                        Keys.onUpPressed: decrementCurrentIndex()
                        Keys.onDownPressed: incrementCurrentIndex()
                        
                        onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)
                        
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
