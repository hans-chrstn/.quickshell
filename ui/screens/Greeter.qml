import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.core
import qs.core.auth
import qs.ui.shared
import qs.ui.shared.auth
import qs.ui.screens.lock

PanelWindow {
    id: root
    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }
    color: "black"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    focusable: true
    property real mouseX: 0
    property real mouseY: 0

    Connections {
        target: AuthManager
        function onStateChanged() {
            if (AuthManager.state === AuthManager.State.Success) {
                root.visible = false
            }

            if (AuthManager.state === AuthManager.State.Finish) {
                contentLoader.active = false
            }
        }
    }

    Loader {
        id: contentLoader
        anchors.fill: parent
        active: true
        sourceComponent: Item {
            anchors.fill: parent
            focus: true

            Shortcut {
                sequence: "Escape"
                enabled: root.visible
                onActivated: {
                    if (AuthManager.currentUser !== "" && !picker.active) {
                        AuthManager.cancelIdentification()
                    }
                    picker.active = false
                }
            }

            Timer {
                id: focusGuard
                interval: 50
                running: root.visible && AuthManager.state !== AuthManager.State.Finish && !picker.active
                repeat: true
                onTriggered: {
                    if (userField.visible && userField.enabled) {
                        if (!userField.activeFocus) userField.forceActiveFocus()
                    } else if (authField.visible && authField.enabled) {
                        if (!authField.activeFocus) authField.forceActiveFocus()
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onPositionChanged: (mouse) => {
                    root.mouseX = (mouse.x - width / 2) / (width / 2)
                    root.mouseY = (mouse.y - height / 2) / (height / 2)
                }
                onClicked: {
                    picker.active = false
                }
            }

            Image {
                id: background
                anchors.fill: parent
                source: {
                    if (WallpaperManager.activeWallpaperPath) {
                        return "file://" + WallpaperManager.activeWallpaperPath
                    }
                    return ""
                }
                fillMode: Image.PreserveAspectCrop
                opacity: 0.3
                visible: contentLoader.active
            }

            MultiEffect {
                anchors.fill: parent
                source: background
                blurEnabled: true
                blur: 0.8
                brightness: -0.25
                autoPaddingEnabled: false
                visible: background.visible
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 0
                width: 400

                IdentityCard {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.bottomMargin: 20
                    visible: {
                        return AuthManager.currentUser !== ""
                    }
                }

                UsernameField {
                    id: userField
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    Layout.bottomMargin: 30
                    visible: {
                        return AuthManager.currentUser === ""
                    }
                }

                AuthenticationField {
                    id: authField
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    Layout.bottomMargin: 30
                    visible: {
                        return AuthManager.currentUser !== ""
                    }
                }

                TerminalLog {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredHeight: 120
                    Layout.fillWidth: true
                    opacity: 0.6
                }
            }

            BaseButton {
                id: sessionTrigger
                anchors {
                    bottom: parent.bottom
                    horizontalCenter: parent.horizontalCenter
                    bottomMargin: 40
                }
                width: 320
                height: 44
                onClicked: {
                    picker.active = true
                }

                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(0, 0, 0, 0.6)
                    border {
                        color: sessionTrigger.isHovered ? ThemeManager.accentColor : ThemeManager.outlinePrimaryColor
                        width: 1
                    }
                    
                    Rectangle { 
                        width: 10
                        height: 1
                        color: ThemeManager.accentColor
                        visible: sessionTrigger.isHovered
                        anchors {
                            top: parent.top
                            left: parent.left
                        }
                    }

                    Rectangle { 
                        width: 1
                        height: 10
                        color: ThemeManager.accentColor
                        visible: sessionTrigger.isHovered
                        anchors {
                            top: parent.top
                            left: parent.left
                        }
                    }

                    Rectangle { 
                        width: 10
                        height: 1
                        color: ThemeManager.accentColor
                        visible: sessionTrigger.isHovered
                        anchors {
                            bottom: parent.bottom
                            right: parent.right
                        }
                    }

                    Rectangle { 
                        width: 1
                        height: 10
                        color: ThemeManager.accentColor
                        visible: sessionTrigger.isHovered
                        anchors {
                            bottom: parent.bottom
                            right: parent.right
                        }
                    }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 15
                        opacity: 0.8

                        StyledLabel {
                            text: "ENVIRONMENT_NODE //"
                            font {
                                pixelSize: 10
                                weight: Font.Black
                            }
                        }

                        StyledLabel {
                            text: SessionManager.currentSessionName.toUpperCase()
                            font {
                                pixelSize: 12
                                weight: Font.Bold
                            }
                            customColor: ThemeManager.accentColor
                        }
                        
                        StyledLabel {
                            text: "󱗘"
                            font {
                                pixelSize: 14
                            }
                            customColor: ThemeManager.accentColor
                        }
                    }
                }
            }

            SessionPicker {
                id: picker
                active: false
            }

            LockScreenClock {
                anchors {
                    top: parent.top
                    horizontalCenter: parent.horizontalCenter
                    topMargin: 60
                }
                scale: 0.6
            }
        }
    }
}
