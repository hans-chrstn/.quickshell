import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.core
import qs.ui.shared
import qs.ui.screens
import qs.ui.screens.settings

PanelWindow {
    id: root
    
    readonly property string screenName: (root.screen) ? root.screen.name : ""
    visible: !!ViewManager.activeWindows["settings"] && (ViewManager.lastActiveScreenName === screenName)
    color: "transparent"

    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    exclusionMode: ExclusionMode.Ignore
    focusable: visible && !closing
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    Shortcut {
        sequence: "Escape"
        enabled: root.visible
        onActivated: {
            ViewManager.closeWindow("settings")
        }
    }

    property bool closing: !!ViewManager.closingWindows["settings"]
    property bool entryActive: false
    readonly property bool showContent: visible && !closing && entryActive

    onVisibleChanged: {
        if (visible) {
            entryTimer.restart()
        } else {
            entryActive = false
        }
    }

    Timer {
        id: entryTimer
        interval: 50
        onTriggered: {
            entryActive = true
            sidebar.forceActiveFocus()
        }
    }

    Rectangle {
        anchors.fill: parent
        color: ThemeManager.shadowPrimaryColor
        opacity: root.showContent ? 0.4 : 0
        
        Behavior on opacity {
            NumberAnimation {
                duration: 300
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                ViewManager.closeWindowByType("settings")
            }
        }
    }

    ClippingRectangle {
        id: windowFrame
        width: 850
        height: 550
        anchors.centerIn: parent
        radius: 28
        color: ThemeManager.backgroundPrimaryColor
        border.color: ThemeManager.outlinePrimaryColor
        border.width: 1
        
        opacity: root.showContent ? 1.0 : 0
        scale: root.showContent ? 1.0 : 0.95

        Behavior on opacity {
            NumberAnimation {
                duration: 300
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: 400
                easing.type: Easing.OutExpo
            }
        }

        MouseArea {
            anchors.fill: parent
            z: -1
            onPressed: (mouse) => {
                mouse.accepted = true
            }
        }

        RowLayout {
            anchors.fill: parent
            spacing: 0

            ConfigurationSidebar {
                id: sidebar
                Layout.fillHeight: true
                activeFocusOnTab: true
                KeyNavigation.tab: settingsListScope
            }

            FocusScope {
                id: settingsListScope
                Layout.fillWidth: true
                Layout.fillHeight: true
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

                    StyledLabel {
                        text: ThemeManager.settingsStructure[sidebar.currentCategoryIndex].category
                        type: "heading"
                    }

                    ListView {
                        id: settingsList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        model: ThemeManager.settingsStructure[sidebar.currentCategoryIndex].items
                        clip: true
                        spacing: 20
                        interactive: true
                        boundsBehavior: Flickable.StopAtBounds
                        
                        footer: Item {
                            height: 40
                        }

                        focus: true
                        Keys.onUpPressed: {
                            decrementCurrentIndex()
                        }
                        Keys.onDownPressed: {
                            incrementCurrentIndex()
                        }

                        onCurrentIndexChanged: {
                            positionViewAtIndex(currentIndex, ListView.Contain)
                        }

                        Behavior on contentY {
                            NumberAnimation {
                                duration: 200
                                easing.type: Easing.OutQuart
                            }
                        }

                        delegate: ConfigurationItemDelegate {
                            width: settingsList.width
                            configurationItemData: modelData
                        }
                    }
                }
            }
        }
    }
}
