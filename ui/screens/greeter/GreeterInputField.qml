import QtQuick
import QtQuick.Layouts
import qs.core
import qs.ui.shared

Rectangle {
    id: root
    
    property var logic
    
    width: 320
    height: 54
    radius: 27
    color: Qt.rgba(1, 1, 1, ThemeManager.lockPasswordOpacity)
    border.color: logic.isErrorMessage ? ThemeManager.dangerColor : Qt.rgba(ColorManager.accentColor.r, ColorManager.accentColor.g, ColorManager.accentColor.b, 0.2)
    border.width: 1

    Item {
        anchors.fill: parent

        Row {
            id: passwordDotRow
            anchors.centerIn: parent
            spacing: 10
            visible: logic.isUserSelected
            
            Repeater {
                model: logic.passwordBuffer.length
                
                Rectangle {
                    width: 10
                    height: 10
                    radius: 5
                    color: ColorManager.accentColor
                    
                    NumberAnimation on scale {
                        from: 0
                        to: 1
                        duration: 150
                        easing.type: Easing.OutBack
                    }
                }
            }
        }

        StyledLabel {
            id: usernameDisplayLabel
            anchors.centerIn: parent
            visible: !logic.isUserSelected
            text: logic.usernameBuffer
            type: "body"
            font.weight: Font.Medium
            font.pixelSize: 16
        }

        StyledLabel {
            anchors.centerIn: parent
            text: logic.isUserSelected ? (logic.passwordBuffer.length === 0 ? "PASSWORD" : "") : ""
            type: "caption"
            opacity: 0.2
            font.weight: Font.Black
            font.letterSpacing: 1
            font.pixelSize: 12
        }

        Rectangle {
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: {
                if (!logic.isUserSelected && logic.usernameBuffer.length > 0) {
                    return (usernameDisplayLabel.implicitWidth / 2) + 4
                }
                return 0
            }
            visible: (!logic.isUserSelected && logic.usernameBuffer.length === 0) || (logic.isUserSelected && logic.passwordBuffer.length === 0)
            width: 2
            height: 20
            color: ColorManager.accentColor

            SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation {
                    to: 0
                    duration: 500
                }
                NumberAnimation {
                    to: 1
                    duration: 500
                }
            }
        }
    }
}
