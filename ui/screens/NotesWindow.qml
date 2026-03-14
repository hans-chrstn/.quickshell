import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.core
import qs.ui.shared
import qs.ui.screens
import qs.ui.screens.notes

PanelWindow {
    id: root
    
    readonly property string screenName: (root.screen) ? root.screen.name : ""
    visible: !!ViewManager.activeWindows["notes"] && (ViewManager.lastActiveScreenName === screenName)
    color: "transparent"

    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    exclusionMode: visible ? ExclusionMode.Normal : ExclusionMode.Ignore
    focusable: visible && !closing
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    property bool closing: !!ViewManager.closingWindows["notes"]
    property bool entryActive: false
    readonly property bool showContent: visible && !closing && entryActive

    onVisibleChanged: {
        if (visible) {
            logic.initialize()
            entryTimer.restart()
        } else {
            logic.cleanup()
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

    NotesLogic {
        id: logic
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
                ViewManager.closeWindowByType("notes")
            }
        }
    }

    ClippingRectangle {
        id: windowFrame
        width: 1200
        height: 800
        anchors.centerIn: parent
        radius: 36
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
            radius: 36
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

        RowLayout {
            anchors.fill: parent
            spacing: 0

            NotesExplorer {
                id: explorer
                logic: logic
            }

            Rectangle {
                width: 1
                Layout.fillHeight: true
                color: ThemeManager.contentOnBackgroundColor
                opacity: 0.05
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                NotesHeader {
                    logic: logic
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: ThemeManager.contentOnBackgroundColor
                    opacity: 0.05
                }

                NotesEditor {
                    logic: logic
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }
        }

        NotesOverlays {
            logic: logic
        }
    }
}
