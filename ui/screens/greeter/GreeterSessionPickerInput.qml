import QtQuick
import QtQuick.Layouts
import qs.core
import qs.ui.shared

RowLayout {
    id: root
    spacing: 10

    Rectangle {
        width: 150
        height: 36
        radius: 18
        color: Qt.rgba(1, 1, 1, 0.05)
        border.color: Qt.rgba(1, 1, 1, 0.1)

        TextInput {
            id: newSessionName
            anchors.fill: parent
            anchors.margins: 10
            color: "white"
            font.family: ThemeManager.fontFamily
            font.pixelSize: 12
            verticalAlignment: Text.AlignVCenter
            clip: true

            StyledLabel {
                text: "NAME"
                type: "caption"
                visible: !parent.text
                opacity: 0.5
                font.pixelSize: 10
                anchors.centerIn: parent
            }
        }
    }

    Rectangle {
        width: 250
        height: 36
        radius: 18
        color: Qt.rgba(1, 1, 1, 0.05)
        border.color: Qt.rgba(1, 1, 1, 0.1)

        TextInput {
            id: newSessionExec
            anchors.fill: parent
            anchors.margins: 10
            color: "white"
            font.family: ThemeManager.fontFamily
            font.pixelSize: 12
            verticalAlignment: Text.AlignVCenter
            clip: true

            StyledLabel {
                text: "EXEC COMMAND"
                type: "caption"
                visible: !parent.text
                opacity: 0.5
                font.pixelSize: 10
                anchors.centerIn: parent
            }
        }
    }

    BaseButton {
        id: addSessionBtn
        width: 80
        height: 36
        readonly property bool canAdd: newSessionName.text.trim() !== "" && newSessionExec.text.trim() !== ""
        enabled: canAdd
        onClicked: {
            SessionManager.addSession(newSessionName.text.trim(), newSessionExec.text.trim())
            newSessionName.text = ""
            newSessionExec.text = ""
        }

        Rectangle {
            anchors.fill: parent
            radius: 18
            color: addSessionBtn.canAdd ? ColorManager.accentColor : Qt.rgba(1, 1, 1, 0.1)
            opacity: addSessionBtn.canAdd ? 1.0 : 0.5
            scale: addSessionBtn.isHovered && addSessionBtn.canAdd ? 1.05 : 1.0
            
            Behavior on scale {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutQuart
                }
            }

            StyledLabel {
                anchors.centerIn: parent
                text: "ADD"
                type: "caption"
                font.weight: Font.Bold
                font.pixelSize: 10
                customColor: addSessionBtn.canAdd ? "black" : "white"
            }
        }
    }
}
