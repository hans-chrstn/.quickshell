import QtQuick
import Quickshell
import qs.ui.shared

Row {
    id: root

    anchors.bottom: parent.bottom
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottomMargin: 30
    spacing: 40
    opacity: 0.4

    BaseButton {
        id: pwrBtn
        width: pwrLabel.implicitWidth
        height: pwrLabel.implicitHeight
        onClicked: {
            Quickshell.execDetached(["systemctl", "poweroff"])
        }

        StyledLabel {
            id: pwrLabel
            text: "󰐥  POWER OFF"
            type: "caption"
            font.weight: Font.Bold
            font.letterSpacing: 1
            font.pixelSize: 9
            opacity: pwrBtn.isHovered ? 1.0 : 0.6
        }
    }

    BaseButton {
        id: rebBtn
        width: rebLabel.implicitWidth
        height: rebLabel.implicitHeight
        onClicked: {
            Quickshell.execDetached(["systemctl", "reboot"])
        }

        StyledLabel {
            id: rebLabel
            text: "󰜉  REBOOT"
            type: "caption"
            font.weight: Font.Bold
            font.letterSpacing: 1
            font.pixelSize: 9
            opacity: rebBtn.isHovered ? 1.0 : 0.6
        }
    }

    BaseButton {
        id: ttyBtn
        width: ttyLabel.implicitWidth
        height: ttyLabel.implicitHeight
        onClicked: {
            Quickshell.execDetached(["chvt", "2"])
        }

        StyledLabel {
            id: ttyLabel
            text: "󰈆  EXIT TO TTY"
            type: "caption"
            font.weight: Font.Bold
            font.letterSpacing: 1
            font.pixelSize: 9
            opacity: ttyBtn.isHovered ? 1.0 : 0.6
        }
    }
}
