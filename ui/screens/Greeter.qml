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

        function onCurrentUserChanged() {
            if (AuthManager.currentUser !== "" && root.bootDone) {
                glitchTimer.start()
            }
        }
    }

    Timer {
        id: glitchTimer

        interval: 16

        repeat: true

        property int ticks: 0

        onTriggered: {
            ticks++
            
            if (ticks < 30) {
                let rand = Math.random()
                
                if (rand > 0.8) {
                    exitTranslate.x = (Math.random() - 0.5) * 100
                    contentLoader.opacity = 0.2
                    glitchTimer.interval = 16
                } else if (rand > 0.6) {
                    exitTranslate.x = 0
                    contentLoader.opacity = 0
                    glitchTimer.interval = 32
                } else if (rand > 0.3) {
                    exitTranslate.x = (Math.random() - 0.5) * 20
                    contentLoader.opacity = 0.8
                    glitchTimer.interval = 16
                } else {
                    exitTranslate.x = 0
                    contentLoader.opacity = 1
                    glitchTimer.interval = 48
                }
            } else {
                exitTranslate.x = 0
                contentLoader.opacity = 1
                ticks = 0
                stop()
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

    TechnicalTopology {
        anchors.fill: parent
        z: -450
        visible: root.bootDone
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

        transform: Translate {
            id: exitTranslate
        }

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
                        if (authField.visible && !authField.isInputFocused) {
                            authField.forceActiveFocus()
                        }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
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
                        active: authField.isActivelyTyping || AuthManager.state === AuthManager.State.Loading
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

            LockScreenClock {
                anchors {
                    bottom: parent.bottom
                    right: parent.right
                    margins: 80
                }
                scale: 0.8
                opacity: {
                    if (AuthManager.currentUser !== "") {
                        return 1
                    }
                    return userField.expansion
                }
            }

            BaseButton {
                id: sessionTrigger

                anchors {
                    top: parent.top
                    right: parent.right
                    margins: 80
                }

                width: 280
                height: 44

                opacity: {
                    if (AuthManager.currentUser !== "") {
                        return 1
                    }
                    return userField.expansion
                }

                visible: root.bootDone

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
                    
                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 15
                        opacity: 0.8

                        StyledLabel {
                            text: "NODE //"
                            font { pixelSize: 10; weight: Font.Black }
                        }

                        StyledLabel {
                            text: SessionManager.currentSessionName.toUpperCase()
                            font { pixelSize: 12; weight: Font.Bold }
                            customColor: ThemeManager.accentColor
                        }
                    }
                }
            }

            SessionPicker {
                id: picker
                active: false
            }
            
            Component.onCompleted: {
                userField.forceActiveFocus()
            }
        }
    }
}
