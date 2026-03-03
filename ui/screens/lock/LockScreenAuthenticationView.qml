import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.core
import qs.ui.shared

ColumnLayout {
    id: root
    
    spacing: 25
    Layout.alignment: Qt.AlignHCenter

    readonly property color accentColor: ThemeManager.accentColor

    ColumnLayout {
        id: userProfileLayout
        Layout.alignment: Qt.AlignHCenter
        spacing: 15
        
        Rectangle {
            id: userAvatarVisual
            Layout.alignment: Qt.AlignHCenter
            width: 100
            height: 100
            radius: 50
            color: Qt.rgba(1, 1, 1, 0.05)
            border.color: root.accentColor
            border.width: 1
            
            StyledLabel { 
                anchors.centerIn: parent
                text: ThemeManager.iconUser
                type: "heading"
                font.pixelSize: 40
                customColor: ThemeManager.contentOnBackgroundColor 
            }
        }
        
        StyledLabel {
            id: userNameLabel
            Layout.alignment: Qt.AlignHCenter
            text: LockManager.authenticationContext ? LockManager.authenticationContext.user : "User"
            type: "title"
            font.weight: Font.DemiBold
            opacity: 0.9
        }
    }

    Rectangle {
        id: passwordInputField
        Layout.alignment: Qt.AlignHCenter
        width: 300
        height: 48
        radius: 24
        color: Qt.rgba(1, 1, 1, ThemeManager.lockPasswordOpacity)
        border.color: LockManager.isErrorMessage ? ThemeManager.dangerColor : Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.3)
        border.width: 1
        
        Rectangle {
            id: innerInputGlow
            anchors.fill: parent
            radius: 24
            color: "transparent"
            border.color: root.accentColor
            border.width: 1
            opacity: 0.1
            anchors.margins: 1
        }

        Row {
            id: passwordDotRow
            anchors.centerIn: parent
            spacing: 10
            
            Repeater {
                model: LockManager.passwordBuffer.length
                
                delegate: Rectangle {
                    width: 10
                    height: 10
                    radius: 5
                    color: root.accentColor
                    
                    NumberAnimation on scale { 
                        from: 0
                        to: 1
                        duration: 150
                        easing.type: Easing.OutBack 
                    }
                }
            }
            
            Rectangle {
                id: caretVisual
                width: 2
                height: 20
                color: root.accentColor
                visible: LockManager.passwordBuffer.length === 0
                
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

        StyledLabel {
            id: passwordPlaceholderLabel
            anchors.centerIn: parent
            text: (LockManager.authenticationContext && LockManager.authenticationContext.isActive) ? "Verifying..." : "Password"
            type: "body"
            opacity: 0.2
            visible: LockManager.passwordBuffer.length === 0
        }
    }
}
