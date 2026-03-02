import QtQuick
import QtQuick.Layouts
import qs.core
import qs.ui.shared

RowLayout {
    id: root
    spacing: 10
    
    property var logic
    property int sessionIndex: -1
    property string sessionName: ""
    property string sessionExec: ""

    BaseButton {
        id: sessionItemBtn
        width: 400
        height: 44
        onClicked: {
            SessionManager.selectSession(root.sessionIndex)
            if (root.logic) {
                root.logic.showSessionPicker = false
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: 22
            color: SessionManager.currentSessionName === root.sessionName ? Qt.rgba(ColorManager.accentColor.r, ColorManager.accentColor.g, ColorManager.accentColor.b, 0.2) : Qt.rgba(1, 1, 1, 0.05)
            border.color: SessionManager.currentSessionName === root.sessionName ? ColorManager.accentColor : "transparent"
            scale: sessionItemBtn.isHovered ? 1.02 : 1.0
            
            Behavior on scale {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutQuart
                }
            }

            StyledLabel {
                anchors.centerIn: parent
                text: root.sessionName.toUpperCase() + "  (" + root.sessionExec + ")"
                type: "body"
                font.pixelSize: 11
                font.letterSpacing: 1
                opacity: 0.8
            }
        }
    }

    BaseButton {
        id: deleteSessionBtn
        width: 44
        height: 44
        onClicked: {
            SessionManager.deleteSession(root.sessionIndex)
        }

        Rectangle {
            anchors.fill: parent
            radius: 22
            color: Qt.rgba(1, 0, 0, 0.1)
            border.color: Qt.rgba(1, 0, 0, 0.2)
            scale: deleteSessionBtn.isHovered ? 1.1 : 1.0
            
            Behavior on scale {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutQuart
                }
            }
            
            StyledLabel {
                anchors.centerIn: parent
                text: ThemeManager.iconTrash
                type: "body"
                customColor: "#ff5555"
                font.pixelSize: 16
            }
        }
    }
}
