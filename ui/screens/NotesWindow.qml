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
    WlrLayershell.keyboardFocus: (visible || notesOverlays.visible) ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    property bool closing: false
    property bool entryActive: false
    readonly property bool showContent: visible && !closing && entryActive

    onVisibleChanged: {
        if (visible) {
            Qt.callLater(() => {
                entryActive = true
            })
            notesLogic.initialize()
        } else {
            entryActive = false
            notesLogic.cleanup()
        }
    }

    NotesLogic {
        id: notesLogic
    }

    Rectangle {
        anchors.fill: parent
        color: ThemeManager.shadowPrimaryColor
        opacity: root.showContent ? 0.75 : 0

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
        width: 1000
        height: 750
        anchors.centerIn: parent
        radius: 40
        color: ThemeManager.backgroundPrimaryColor
        border.color: ThemeManager.outlinePrimaryColor
        border.width: 1

        opacity: root.showContent ? 1.0 : 0
        scale: root.showContent ? 1.0 : 0.98

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

        RowLayout {
            anchors.fill: parent
            spacing: 0

            NotesExplorer {
                logic: notesLogic
            }

            Rectangle {
                width: 1
                Layout.fillHeight: true
                color: ThemeManager.surfaceContentColor
                opacity: 0.05
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                NotesHeader {
                    logic: notesLogic
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: ThemeManager.surfaceContentColor
                    opacity: 0.05
                }

                NotesEditor {
                    logic: notesLogic
                }
            }
        }

        NotesOverlays {
            id: notesOverlays
            logic: notesLogic
        }
    }

    Shortcut {
        sequence: "Ctrl+S"
        onActivated: {
            NotesManager.saveNotes()
        }
    }
    Shortcut {
        sequence: "Escape"
        onActivated: {
            if (notesLogic.isSaveAsActive) {
                notesLogic.cancelSaveAs()
            } else if (notesLogic.pendingDeletePath !== "") {
                notesLogic.cancelDelete()
            } else {
                ViewManager.closeWindowByType("notes")
            }
        }
    }
}
