import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.core
import qs.ui.shared
import "./taskmanager"

PanelWindow {
    id: root

    visible: false
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

    property bool closing: false
    property bool entryActive: false
    readonly property bool showContent: visible && !closing && entryActive

    onVisibleChanged: {
        if (visible) {
            ProcessManager.startMonitoring()
            Qt.callLater(() => {
                entryActive = true
            })
        } else {
            ProcessManager.stopMonitoring()
            entryActive = false
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
                ViewManager.closeWindowByType("taskManager")
            }
        }
    }

    ClippingRectangle {
        id: windowFrame
        width: 1000
        height: 700
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

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 32
            spacing: 24

            TaskManagerHeader { }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: ThemeManager.contentOnBackgroundColor
                opacity: 0.05
            }

            ListView {
                id: processList
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: ProcessManager.model
                spacing: 4
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                header: Item {
                    width: processList.width
                    height: 30
                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        StyledLabel {
                            text: "PID"
                            type: "caption"
                            width: 80
                            opacity: 0.4
                        }
                        StyledLabel {
                            text: "NAME"
                            type: "caption"
                            width: 600
                            opacity: 0.4
                        }
                        StyledLabel {
                            text: "CPU %"
                            type: "caption"
                            width: 80
                            horizontalAlignment: Text.AlignRight
                            opacity: 0.4
                        }
                        StyledLabel {
                            text: "MEM %"
                            type: "caption"
                            width: 80
                            horizontalAlignment: Text.AlignRight
                            opacity: 0.4
                        }
                    }
                }

                delegate: TaskManagerListDelegate {
                    width: processList.width
                    height: 44
                    modelData: model
                }
            }
        }
    }
}
