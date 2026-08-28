import QtQuick
import QtQuick.Controls
import qs.core
import qs.ui.shared

Item {
    id: root

    property alias text: textInput.text
    property string placeholder: ""
    property bool isPassword: false
    property color textColor: "#f5f5f7"
    property color placeholderColor: Qt.rgba(0.96, 0.96, 0.97, 0.15)
    property bool showPlaceholder: true

    signal accepted()

    clip: true

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: "#1c1c1e"
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: parent.height / 2 - 1
        color: "#101012"
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: parent.height / 2 - 1
        color: "transparent"
        border.color: textInput.activeFocus ? ThemeManager.accentColor : ThemeManager.outlineStrongColor
        border.width: 1
        Behavior on border.color { ColorAnimation { duration: 150 } }
    }

    Text {
        anchors.left: parent.left
        anchors.leftMargin: 18
        anchors.right: parent.right
        anchors.rightMargin: 18
        anchors.verticalCenter: parent.verticalCenter
        text: root.placeholder
        font.family: ThemeManager.fontFamily
        font.pixelSize: 14
        font.weight: Font.Medium
        color: ThemeManager.contentOnBackgroundColor
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        opacity: root.showPlaceholder && !textInput.text && !textInput.activeFocus ? 0.15 : 0.0
        visible: opacity > 0.01
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }

    TextInput {
        id: textInput
        anchors.left: parent.left
        anchors.leftMargin: 18
        anchors.right: parent.right
        anchors.rightMargin: 18
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height
        verticalAlignment: TextInput.AlignVCenter
        color: root.textColor
        font.family: ThemeManager.fontFamily
        font.pixelSize: 14
        font.weight: Font.Medium
        selectedTextColor: "#111111"
        selectionColor: ThemeManager.accentColor
        clip: true
        echoMode: root.isPassword ? TextInput.Password : TextInput.Normal

        onAccepted: root.accepted()
    }
}
