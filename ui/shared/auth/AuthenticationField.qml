import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import qs.core
import qs.core.auth
import qs.ui.shared

Item {
    id: root

    implicitWidth: 400

    implicitHeight: 44

    visible: AuthManager.currentUser !== ""

    property bool isInputFocused: input.activeFocus

    property real expandWidth: 0

    property real expandHeight: 0

    onVisibleChanged: {
        if (visible) {
            introAnim.start()
        } else {
            root.expandWidth = 0
            root.expandHeight = 0
        }
    }

    SequentialAnimation {
        id: introAnim

        NumberAnimation {
            target: root
            property: "expandWidth"
            to: 1
            duration: 400
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: root
            property: "expandHeight"
            to: 1
            duration: 400
            easing.type: Easing.OutQuart
        }
    }

    Rectangle {
        id: container

        anchors.centerIn: parent

        width: 400 * root.expandWidth

        height: 44 * root.expandHeight

        color: Qt.rgba(0, 0, 0, 0.4)

        border {
            color: {
                if (input.activeFocus) {
                    return ThemeManager.accentColor
                }
                return ThemeManager.outlinePrimaryColor
            }
            width: 1
        }

        clip: true

        opacity: {
            if (root.expandHeight > 0.1) {
                return 1
            }
            return 0
        }

        Behavior on opacity {
            NumberAnimation { 
                duration: 200 
            }
        }

        Rectangle { 
            width: 8
            height: 1
            color: ThemeManager.accentColor
            z: 20

            visible: {
                return input.activeFocus && 
                       root.expandWidth > 0.9
            }

            anchors {
                top: parent.top
                left: parent.left
            }
        }

        Rectangle { 
            width: 1
            height: 8
            color: ThemeManager.accentColor
            z: 20

            visible: {
                return input.activeFocus && 
                       root.expandHeight > 0.9
            }

            anchors {
                top: parent.top
                left: parent.left
            }
        }

        Rectangle { 
            width: 8
            height: 1
            color: ThemeManager.accentColor
            z: 20

            visible: {
                return input.activeFocus && 
                       root.expandWidth > 0.9
            }

            anchors {
                bottom: parent.bottom
                right: parent.right
            }
        }

        Rectangle { 
            width: 1
            height: 8
            color: ThemeManager.accentColor
            z: 20

            visible: {
                return input.activeFocus && 
                       root.expandHeight > 0.9
            }

            anchors {
                bottom: parent.bottom
                right: parent.right
            }
        }

        TextField {
            id: input

            anchors {
                fill: parent
                leftMargin: 12
                rightMargin: 12
            }

            font {
                pixelSize: 16
                letterSpacing: 6
            }

            echoMode: TextInput.Password

            passwordCharacter: "█"

            color: ThemeManager.surfaceContentColor

            selectionColor: ThemeManager.accentColor

            selectedTextColor: "white"

            verticalAlignment: TextInput.AlignVCenter

            horizontalAlignment: TextInput.AlignLeft

            background: null

            opacity: {
                if (root.expandHeight > 0.8) {
                    return 1
                }
                return 0
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                }
            }

            onAccepted: {
                AuthManager.authenticate(input.text)
                input.text = ""
            }

            cursorDelegate: Rectangle {
                width: 10
                height: 20
                color: ThemeManager.accentColor

                visible: input.activeFocus

                SequentialAnimation on opacity {
                    running: AuthManager.state !== AuthManager.State.Finish
                    loops: Animation.Infinite
                    NumberAnimation { from: 1; to: 1; duration: 500 }
                    NumberAnimation { from: 1; to: 0; duration: 100 }
                    NumberAnimation { from: 0; to: 0; duration: 400 }
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

            visible: {
                return input.text === "" && 
                       root.expandHeight > 0.9
            }
        }
    }

    function forceActiveFocus() {
        input.forceActiveFocus()
    }
}
