import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import qs.core
import qs.core.auth
import qs.ui.shared

TextField {
    id: root
    implicitWidth: 400
    implicitHeight: 44
    font {
        pixelSize: 16
        letterSpacing: 6
    }
    echoMode: TextInput.Password
    passwordCharacter: "█"
    color: ThemeManager.surfaceContentColor
    selectionColor: ThemeManager.accentColor
    selectedTextColor: "white"
    leftPadding: 12
    rightPadding: 12
    verticalAlignment: TextInput.AlignVCenter
    horizontalAlignment: TextInput.AlignLeft
    activeFocusOnTab: true

    onVisibleChanged: {
        if (
            !visible
        ) {
            root.focus = false
        }
    }

    background: Rectangle {
        color: Qt.rgba(0, 0, 0, 0.4)
        border {
            color: root.activeFocus ? ThemeManager.accentColor : ThemeManager.outlinePrimaryColor
            width: 1
        }

        Rectangle { 
            width: 8
            height: 1
            color: ThemeManager.accentColor
            visible: root.activeFocus
            anchors {
                top: parent.top
                left: parent.left
            }
        }

        Rectangle { 
            width: 1
            height: 8
            color: ThemeManager.accentColor
            visible: root.activeFocus
            anchors {
                top: parent.top
                left: parent.left
            }
        }

        Rectangle { 
            width: 8
            height: 1
            color: ThemeManager.accentColor
            visible: root.activeFocus
            anchors {
                bottom: parent.bottom
                right: parent.right
            }
        }

        Rectangle { 
            width: 1
            height: 8
            color: ThemeManager.accentColor
            visible: root.activeFocus
            anchors {
                bottom: parent.bottom
                right: parent.right
            }
        }

        SequentialAnimation on x {
            id: errorAnimation
            running: AuthManager.state === AuthManager.State.Failed
            NumberAnimation { 
                to: -10
                duration: 50
                easing.type: Easing.OutQuad 
            }
            NumberAnimation { 
                to: 10
                duration: 50
                easing.type: Easing.OutQuad 
            }
            NumberAnimation { 
                to: -10
                duration: 50
                easing.type: Easing.OutQuad 
            }
            NumberAnimation { 
                to: 10
                duration: 50
                easing.type: Easing.OutQuad 
            }
            NumberAnimation { 
                to: 0
                duration: 50
                easing.type: Easing.OutQuad 
            }
        }
    }

    StyledLabel {
        anchors {
            left: parent.left
            leftMargin: 12
            verticalCenter: parent.verticalCenter
        }
        text: "PASSCODE_PROTOCOL..."
        font {
            pixelSize: 14
        }
        customColor: ThemeManager.surfaceContentColor
        opacity: 0.2
        visible: root.text === ""
    }

    cursorDelegate: Rectangle {
        width: 10
        height: 20
        color: ThemeManager.accentColor
        visible: root.activeFocus
        SequentialAnimation on opacity {
            running: AuthManager.state !== AuthManager.State.Finish
            loops: Animation.Infinite
            NumberAnimation { from: 1; to: 1; duration: 500 }
            NumberAnimation { from: 1; to: 0; duration: 100 }
            NumberAnimation { from: 0; to: 0; duration: 400 }
        }
    }

    onAccepted: {
        AuthManager.authenticate(root.text)
        root.text = ""
    }

    enabled: {
        return AuthManager.currentUser !== ""
    }
}
