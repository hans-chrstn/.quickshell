import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import qs.core
import qs.core.auth
import qs.ui.shared

TextField {
    id: root
    implicitWidth: 400
    implicitHeight: 44
    font {
        pixelSize: 16
        letterSpacing: 2
    }
    color: ThemeManager.surfaceContentColor
    selectionColor: ThemeManager.accentColor
    selectedTextColor: "white"
    leftPadding: 12
    rightPadding: 12
    verticalAlignment: TextInput.AlignVCenter
    horizontalAlignment: TextInput.AlignLeft
    activeFocusOnTab: true

    onVisibleChanged: {
        if (
            !visible
        ) {
            root.focus = false
        }
    }

    background: Rectangle {
        color: Qt.rgba(0, 0, 0, 0.4)
        border {
            color: root.activeFocus ? ThemeManager.accentColor : ThemeManager.outlinePrimaryColor
            width: 1
        }

        Rectangle { 
            width: 8
            height: 1
            color: ThemeManager.accentColor
            visible: root.activeFocus
            anchors {
                top: parent.top
                left: parent.left
            }
        }

        Rectangle { 
            width: 1
            height: 8
            color: ThemeManager.accentColor
            visible: root.activeFocus
            anchors {
                top: parent.top
                left: parent.left
            }
        }

        Rectangle { 
            width: 8
            height: 1
            color: ThemeManager.accentColor
            visible: root.activeFocus
            anchors {
                bottom: parent.bottom
                right: parent.right
            }
        }

        Rectangle { 
            width: 1
            height: 8
            color: ThemeManager.accentColor
            visible: root.activeFocus
            anchors {
                bottom: parent.bottom
                right: parent.right
            }
        }
    }

    StyledLabel {
        anchors {
            left: parent.left
            leftMargin: 12
            verticalCenter: parent.verticalCenter
        }
        text: "USER_IDENTIFICATION..."
        font {
            pixelSize: 14
        }
        customColor: ThemeManager.surfaceContentColor
        opacity: 0.2
        visible: root.text === ""
    }

    cursorDelegate: Rectangle {
        width: 10
        height: 20
        color: ThemeManager.accentColor
        visible: root.activeFocus
        SequentialAnimation on opacity {
            loops: Animation.Infinite
            NumberAnimation { from: 1; to: 1; duration: 500 }
            NumberAnimation { from: 1; to: 0; duration: 100 }
            NumberAnimation { from: 0; to: 0; duration: 400 }
        }
    }

    onAccepted: {
        if (root.text.trim() !== "") {
            AuthManager.identify(root.text.trim())
        }
    }
}
