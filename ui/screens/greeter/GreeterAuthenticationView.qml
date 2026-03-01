import QtQuick
import QtQuick.Layouts
import qs.core
import qs.ui.shared
import qs.ui.screens.lock

ColumnLayout {
    id: root

    property var logic
    property real mouseX: 0
    property real mouseY: 0

    spacing: ThemeManager.lockContentSpacing

    LockScreenClock { }

    ColumnLayout {
        spacing: 25
        Layout.alignment: Qt.AlignHCenter

        GreeterAvatar {
            logic: root.logic
        }

        GreeterInputField {
            logic: root.logic
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 15
            opacity: 0.3

            StyledLabel {
                text: root.logic.isUserSelected ? "󰌾  ESC TO CHANGE USER" : "󰌾  ENTER TO SELECT"
                type: "caption"
                font.weight: Font.Bold
                font.letterSpacing: 1
                font.pixelSize: 8
            }
        }

        GreeterSessionToggle {
            logic: root.logic
            Layout.alignment: Qt.AlignHCenter
        }
    }

    Item {
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: 350
        Layout.preferredHeight: 30

        StyledLabel {
            anchors.centerIn: parent
            text: root.logic.statusMessage.toUpperCase()
            type: "caption"
            customColor: root.logic.isErrorMessage ? ThemeManager.dangerColor : ThemeManager.accentColor
            font.weight: Font.Black
            font.letterSpacing: 1.5
            font.pixelSize: 10
            opacity: text ? 0.8 : 0.0
            
            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                }
            }
        }
    }
}
