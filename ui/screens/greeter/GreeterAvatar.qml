import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Greetd
import qs.core
import qs.ui.shared

ColumnLayout {
    id: root
    
    property var logic
    spacing: 15
    Layout.alignment: Qt.AlignHCenter

    Item {
        Layout.alignment: Qt.AlignHCenter
        width: 100
        height: 100

        Rectangle {
            anchors.fill: parent
            radius: 50
            color: Qt.rgba(1, 1, 1, 0.05)
            border.color: ColorManager.accentColor
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "󰀉"
                font.pixelSize: 44
                color: ThemeManager.contentOnBackgroundColor
                opacity: 0.8
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: 50
            color: "transparent"
            border.color: ThemeManager.accentColor
            border.width: 2
            visible: logic.isUserSelected
            scale: logic.isUserSelected ? 1.1 : 1.0
            opacity: logic.isUserSelected ? 0.5 : 0
            
            Behavior on scale {
                NumberAnimation {
                    duration: 400
                    easing.type: Easing.OutBack
                }
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: 400
                }
            }
        }
    }

    StyledLabel {
        id: userDisplayLabel
        Layout.alignment: Qt.AlignHCenter
        text: logic.isUserSelected ? Greetd.user.toUpperCase() : (logic.usernameBuffer || "TYPE USERNAME").toUpperCase()
        type: "greeterUser"
        opacity: logic.usernameBuffer || logic.isUserSelected ? 0.9 : 0.2
        
        Behavior on opacity {
            NumberAnimation {
                duration: 200
            }
        }
    }
}
