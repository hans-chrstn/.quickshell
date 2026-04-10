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

    color: "#000000"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    focusable: true

    property real mouseX: 0

    property real mouseY: 0
    
    property bool bootDone: false

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

    Rectangle {
        anchors.fill: parent
        color: "black"
        z: -1000
    }

    TechnicalGrid {
        anchors.fill: parent
        z: -500
    }

    BootLogo {
        id: bootLogo

        anchors.fill: parent

        visible: !root.bootDone || contentLoader.status !== Loader.Ready

        onFinished: {
            root.bootDone = true
            contentLoader.active = true
        }

        z: 100
    }

    Loader {
        id: contentLoader

        anchors.fill: parent

        active: false

        visible: status === Loader.Ready

        sourceComponent: Item {
            id: mainContent

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

                interval: 100

                running: {
                    return root.visible && 
                           root.bootDone &&
                           AuthManager.state !== AuthManager.State.Finish && 
                           !picker.active
                }

                repeat: true

                onTriggered: {
                    if (AuthManager.currentUser === "") {
                        if (userField.visible && !userField.isInputFocused) {
                            userField.forceActiveFocus()
                        }
                    } else {
                        if (authField.visible && !authField.focus) {
                            authField.forceActiveFocus()
                        }
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

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 0
                width: 440

                Item {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 440
                    Layout.preferredHeight: 160
                    Layout.bottomMargin: 20

                    IdentityCard {
                        anchors.centerIn: parent
                        visible: AuthManager.currentUser !== ""
                    }

                    UsernameField {
                        id: userField
                        anchors.centerIn: parent
                        visible: AuthManager.currentUser === "" || expansion > 0.01
                    }
                }

                AuthenticationField {
                    id: authField

                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    Layout.bottomMargin: 30

                    visible: AuthManager.currentUser !== ""
                }

                TerminalLog {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredHeight: 120
                    Layout.fillWidth: true
                    opacity: 0.6
                    
                    active: root.bootDone
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

                opacity: {
                    if (AuthManager.currentUser !== "") {
                        return 1
                    }
                    return userField.expansion
                }

                visible: {
                    return root.bootDone
                }

                onClicked: {
                    picker.active = true
                }

                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(0, 0, 0, 0.6)

                    border {
                        color: {
                            if (sessionTrigger.isHovered) {
                                return ThemeManager.accentColor
                            }
                            return ThemeManager.outlinePrimaryColor
                        }
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
                
                opacity: {
                    if (AuthManager.currentUser !== "") {
                        return 1
                    }
                    return userField.expansion
                }

                visible: {
                    return root.bootDone
                }
            }
            
            Component.onCompleted: {
                userField.forceActiveFocus()
            }
        }
    }
}
