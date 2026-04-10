import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import qs.core
import qs.core.auth
import qs.ui.shared

Item {
    id: root

    implicitWidth: 440

    implicitHeight: 60

    property alias text: input.text

    property bool isInputFocused: input.activeFocus

    property real expansion: 0

    property real diamondOffset: 0

    function forceActiveFocus() {
        input.forceActiveFocus()
    }

    state: "Collapsed"

    states: [
        State {
            name: "Collapsed"
            PropertyChanges { target: root; expansion: 0 }
            PropertyChanges { target: root; diamondOffset: 0 }
        },
        State {
            name: "Expanded"
            PropertyChanges { target: root; expansion: 1 }
            PropertyChanges { target: root; diamondOffset: -200 }
        }
    ]

    transitions: [
        Transition {
            from: "Collapsed"
            to: "Expanded"
            SequentialAnimation {
                NumberAnimation { 
                    target: root
                    property: "diamondOffset"
                    to: -200
                    duration: 600
                    easing.type: Easing.OutBack
                }
                NumberAnimation { 
                    target: root
                    property: "expansion"
                    to: 1
                    duration: 500
                    easing.type: Easing.OutCubic
                }
            }
        },
        Transition {
            from: "Expanded"
            to: "Collapsed"
            SequentialAnimation {
                NumberAnimation { 
                    target: root
                    property: "expansion"
                    to: 0
                    duration: 400
                    easing.type: Easing.InCubic
                }
                NumberAnimation { 
                    target: root
                    property: "diamondOffset"
                    to: 0
                    duration: 500
                    easing.type: Easing.InOutBack
                }
            }
        }
    ]

    Connections {
        target: AuthManager
        function onCurrentUserChanged() {
            if (AuthManager.currentUser === "") {
                root.state = "Expanded"
            } else {
                root.state = "Collapsed"
            }
        }
    }

    Component.onCompleted: {
        if (AuthManager.currentUser === "") {
            root.state = "Expanded"
        }
    }

    Rectangle {
        id: inputBackground

        height: 44

        width: 400 * root.expansion

        color: Qt.rgba(0, 0, 0, 0.6)

        z: 1

        border {
            color: {
                if (input.activeFocus) {
                    return ThemeManager.accentColor
                }
                return ThemeManager.outlinePrimaryColor
            }
            width: 1
        }

        anchors {
            verticalCenter: parent.verticalCenter
            left: diamond.horizontalCenter
            leftMargin: 0
        }

        clip: true

        TextField {
            id: input

            anchors {
                fill: parent
                leftMargin: 25
                rightMargin: 15
            }

            font {
                pixelSize: 16
                letterSpacing: 2
            }

            color: ThemeManager.surfaceContentColor

            selectionColor: ThemeManager.accentColor

            selectedTextColor: "white"

            verticalAlignment: TextInput.AlignVCenter

            horizontalAlignment: TextInput.AlignLeft

            background: null

            opacity: root.expansion > 0.8 ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                }
            }

            onAccepted: {
                if (input.text.trim() !== "") {
                    AuthManager.identify(input.text.trim())
                }
            }
        }

        StyledLabel {
            anchors {
                left: parent.left
                leftMargin: 25
                verticalCenter: parent.verticalCenter
            }

            text: "USER_IDENTIFICATION..."

            font {
                pixelSize: 14
            }

            customColor: ThemeManager.surfaceContentColor

            opacity: 0.2

            visible: {
                return input.text === "" && 
                       root.expansion > 0.9
            }
        }
    }

    Rectangle {
        id: diamond

        width: 40

        height: 40

        color: "black"

        z: 2

        border {
            color: ThemeManager.accentColor
            width: 2
        }

        rotation: 45

        anchors {
            verticalCenter: parent.verticalCenter
            horizontalCenter: parent.horizontalCenter
            horizontalCenterOffset: root.diamondOffset
        }
    }
}
