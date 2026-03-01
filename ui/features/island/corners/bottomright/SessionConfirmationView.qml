import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.core
import qs.ui.shared

ColumnLayout {
    id: root

    property string currentAction: ""
    property bool isConfirming: currentAction !== ""

    spacing: 20

    opacity: root.isConfirming ? 1 : 0
    scale: root.isConfirming ? 1.0 : 1.1
    visible: opacity > 0.01

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
        spacing: 4
        Layout.alignment: Qt.AlignHCenter

        Text {
            id: confirmationQuestionLabel
            text: "ARE YOU SURE?"
            color: ThemeManager.contentOnBackgroundColor
            font.pixelSize: 10
            font.weight: Font.Black
            font.letterSpacing: 1
            Layout.alignment: Qt.AlignHCenter
        }
        Text {
            id: actionTypeLabel
            text: root.currentAction.toUpperCase()
            color: root.currentAction === "poweroff" ? ThemeManager.dangerPrimaryColor : ThemeManager.accentColor
            font.pixelSize: 12
            font.weight: Font.Bold
            font.letterSpacing: 2
            Layout.alignment: Qt.AlignHCenter
        }
    }

    RowLayout {
        spacing: 16
        Layout.alignment: Qt.AlignHCenter

        BaseButton {
            id: confirmYesButton
            Layout.preferredWidth: 60
            Layout.preferredHeight: 40
            onClicked: {
                SoundManager.playSuccess()
                if (root.currentAction === "logout") {
                    Quickshell.execDetached(["loginctl", "terminate-user", Quickshell.env("USER")])
                } else {
                    Quickshell.execDetached(["systemctl", "poweroff"])
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: 20
                color: root.currentAction === "poweroff" ? ThemeManager.dangerPrimaryColor : ThemeManager.accentColor

                Text {
                    anchors.centerIn: parent
                    text: "YES"
                    color: ThemeManager.contentPrimaryColor
                    font.pixelSize: 11
                    font.weight: Font.Black
                }
            }
        }

        BaseButton {
            id: confirmNoButton
            Layout.preferredWidth: 60
            Layout.preferredHeight: 40
            onClicked: {
                SoundManager.playClick()
                root.currentAction = ""
            }

            Rectangle {
                anchors.fill: parent
                radius: 20
                color: ThemeManager.contentOnBackgroundColor
                opacity: confirmNoButton.isHovered ? 0.15 : 0.1
                Behavior on opacity {
                    NumberAnimation {
                        duration: 200
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: "NO"
                    color: ThemeManager.contentOnBackgroundColor
                    font.pixelSize: 11
                    font.weight: Font.Bold
                }
            }
        }
    }
}
