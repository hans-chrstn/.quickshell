import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.ui.shared
import qs.core
import qs.ui.screens.controlpanel

PanelWindow {
    id: root
    
    readonly property string screenName: (root.screen) ? root.screen.name : ""
    visible: !!ViewManager.activeWindows["network"] && (ViewManager.lastActiveScreenName === screenName)
    color: "transparent"

    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }
    exclusionMode: visible ? ExclusionMode.Normal : ExclusionMode.Ignore
    focusable: visible && !closing

    Shortcut {
        sequence: "Escape"
        enabled: root.visible
        onActivated: {
            ViewManager.closeWindowByType("network")
        }
    }

    property bool closing: !!ViewManager.closingWindows["network"]
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
        }
    }

    Rectangle {
        anchors.fill: parent
        color: ThemeManager.shadowPrimaryColor
        opacity: root.showContent ? 0.6 : 0
        
        Behavior on opacity {
            NumberAnimation {
                duration: 300
            }
        }
        
        MouseArea {
            anchors.fill: parent
            onClicked: {
                ViewManager.closeWindowByType("network")
            }
        }
    }

    ClippingRectangle {
        id: windowFrame
        width: 600
        height: 550
        anchors.centerIn: parent
        radius: 32
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
            onPressed: (mouse) => {
                mouse.accepted = true
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: 32
            color: "transparent"
            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: Qt.rgba(ThemeManager.contentOnBackgroundColor.r, ThemeManager.contentOnBackgroundColor.g, ThemeManager.contentOnBackgroundColor.b, 0.02)
                }
                GradientStop {
                    position: 0.5
                    color: "transparent"
                }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 32
            spacing: 20

            ControlPanelHeader {
                activePage: "wifi"
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: ThemeManager.contentOnBackgroundColor
                opacity: 0.05
            }

            ControlPanelList {
                activePage: "wifi"
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.topMargin: 10
                Layout.bottomMargin: 10
            }

            NetworkPanelFooter {
                panelType: "wifi"
                Layout.fillWidth: true
            }
        }
    }
}
