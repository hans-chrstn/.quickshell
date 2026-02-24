import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services

ColumnLayout {
    id: root
    spacing: 25
    Layout.alignment: Qt.AlignHCenter

    readonly property color accent: ColorService.accent

    ColumnLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 15
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 100; height: 100; radius: 50
            color: Qt.rgba(1, 1, 1, 0.05); border.color: root.accent; border.width: 1
            Text { anchors.centerIn: parent; text: "󰀉"; font.pixelSize: 40; color: "white" }
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: LockService.pamContext ? LockService.pamContext.user : "User"
            color: "white"; font.pixelSize: 20; font.weight: Font.DemiBold; opacity: 0.9
        }
    }

    Rectangle {
        id: pwField
        Layout.alignment: Qt.AlignHCenter
        width: 300; height: 48; radius: 24
        color: Qt.rgba(1, 1, 1, ThemeService.lockPasswordOpacity)
        border.color: LockService.messageIsError ? ThemeService.dangerColor : Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.3)
        border.width: 1
        
        Rectangle {
            anchors.fill: parent; radius: 24; color: "transparent"; border.color: root.accent; border.width: 1; opacity: 0.1; anchors.margins: 1
        }

        Row {
            anchors.centerIn: parent; spacing: 10
            Repeater {
                model: LockService.buffer.length
                Rectangle {
                    width: 10; height: 10; radius: 5; color: root.accent
                    NumberAnimation on scale { from: 0; to: 1; duration: 150; easing.type: Easing.OutBack }
                }
            }
            Rectangle {
                width: 2; height: 20; color: root.accent
                visible: LockService.buffer.length === 0
                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    NumberAnimation { to: 0; duration: 500 }
                    NumberAnimation { to: 1; duration: 500 }
                }
            }
        }

        Text {
            anchors.centerIn: parent
            text: (LockService.pamContext && LockService.pamContext.isActive) ? "Verifying..." : "Password"
            color: "white"; opacity: 0.2; font.pixelSize: 14; visible: LockService.buffer.length === 0
        }
    }
}
