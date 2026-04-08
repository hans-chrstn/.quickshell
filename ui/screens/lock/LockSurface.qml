pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.core
import qs.core.auth
import qs.ui.shared
import qs.ui.shared.auth
import qs.ui.screens.lock

WlSessionLockSurface {
    id: root
    required property WlSessionLock lock
    color: "black"

    Connections {
        target: AuthManager
        function onStateChanged() {
            if (AuthManager.state === AuthManager.State.Finish) {
                dismissAnim.start()
            }
        }
    }

    Timer {
        id: protocolReleaseTimer
        interval: 50
        repeat: false
        onTriggered: {
            if (root.lock) {
                root.lock.locked = false
            }
        }
    }

    SequentialAnimation {
        id: dismissAnim
        ParallelAnimation {
            NumberAnimation { 
                target: backgroundContainer
                property: "opacity"
                to: 0
                duration: 300 
            }
            NumberAnimation { 
                target: content
                property: "scale"
                to: 0.9
                duration: 300
                easing.type: Easing.InCubic 
            }
            NumberAnimation { 
                target: content
                property: "opacity"
                to: 0
                duration: 300 
            }
        }
        ScriptAction {
            script: {
                protocolReleaseTimer.start()
            }
        }
    }

    ParallelAnimation {
        id: initAnim
        running: true
        NumberAnimation { 
            target: backgroundContainer
            property: "opacity"
            from: 0
            to: 1
            duration: 500 
        }
        NumberAnimation { 
            target: content
            property: "scale"
            from: 0.8
            to: 1
            duration: 500
            easing.type: Easing.OutBack 
        }
        NumberAnimation { 
            target: content
            property: "opacity"
            from: 0
            to: 1
            duration: 500 
        }
    }

    Rectangle {
        id: mainRect
        anchors {
            fill: parent
        }
        color: "black"
        focus: true

        Timer {
            id: focusGuard
            interval: 200
            running: {
                return root.lock && 
                       root.lock.locked && 
                       AuthManager.state !== AuthManager.State.Finish
            }
            repeat: true
            onTriggered: {
                if (!authField.activeFocus) {
                    authField.forceActiveFocus()
                }
            }
        }

        property real mouseX: 0
        property real mouseY: 0
        
        MouseArea {
            anchors {
                fill: parent
            }
            hoverEnabled: true
            onPositionChanged: (mouse) => {
                mainRect.mouseX = (mouse.x - width / 2) / (width / 2)
                mainRect.mouseY = (mouse.y - height / 2) / (height / 2)
            }
            onPressed: (mouse) => {
                if (AuthManager.state !== AuthManager.State.Finish) {
                    authField.forceActiveFocus()
                }
                mouse.accepted = true
            }
        }

        LazyContainer {
            id: backgroundContainer
            anchors {
                fill: parent
            }
            opacity: 0
            component: LockScreenBackground {
                relativeMouseX: mainRect.mouseX
                relativeMouseY: mainRect.mouseY
            }
        }

        LazyContainer {
            id: statusBarContainer
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                topMargin: 60
                leftMargin: 60
                rightMargin: 60
            }
            height: 60
            opacity: content.opacity
            component: LockScreenStatusBar { }
        }

        Item {
            id: content
            anchors {
                centerIn: parent
            }
            width: innerLayout.implicitWidth
            height: innerLayout.implicitHeight
            scale: 0.8
            opacity: 0
            transform: Translate {
                x: mainRect.mouseX * 10
                y: mainRect.mouseY * 10
                Behavior on x { 
                    NumberAnimation { 
                        duration: 1000
                        easing.type: Easing.OutCubic 
                    } 
                }
                Behavior on y { 
                    NumberAnimation { 
                        duration: 1000
                        easing.type: Easing.OutCubic 
                    } 
                }
            }

            ColumnLayout {
                id: innerLayout
                anchors {
                    centerIn: parent
                }
                spacing: 24
                LockScreenClock {
                    Layout.alignment: Qt.AlignHCenter
                }
                IdentityCard {
                    Layout.alignment: Qt.AlignHCenter
                }
                AuthenticationField {
                    id: authField
                    Layout.alignment: Qt.AlignHCenter
                    Component.onCompleted: {
                        authField.forceActiveFocus()
                    }
                }
                TerminalLog {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredHeight: 100
                    Layout.preferredWidth: 400
                }
                LazyContainer {
                    id: mediaControlsWrapper
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 400
                    Layout.preferredHeight: 150
                    component: LockScreenMediaControls { }
                }
            }
        }
    }
}
