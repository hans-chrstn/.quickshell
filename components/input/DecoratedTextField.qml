import QtQuick
import qs.core

Item {
    id: root

    property alias text: editor.text
    property string label: ""
    property string placeholderText: ""
    property string supportingText: ""
    property bool invalid: false
    property int maximumLength: 256
    signal accepted()

    implicitWidth: 260
    implicitHeight: label.length > 0 || supportingText.length > 0 ? 67 : 38

    Text {
        id: labelText
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        visible: root.label.length > 0
        text: root.label
        color: Design.textMuted
        font.family: Design.fontText
        font.pixelSize: 10
        font.weight: Font.Medium
        elide: Text.ElideRight
    }

    Rectangle {
        id: field
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: labelText.visible ? labelText.bottom : parent.top
        anchors.topMargin: labelText.visible ? 6 : 0
        height: 36
        radius: 11
        color: Design.surfaceRaised
        border.width: 1
        border.color: root.invalid ? Design.red
            : editor.activeFocus ? Design.blue : Design.separator

        Behavior on border.color { ColorAnimation { duration: 110 } }

        TextInput {
            id: editor
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            verticalAlignment: TextInput.AlignVCenter
            color: Design.text
            selectionColor: Design.blue
            selectedTextColor: Design.text
            font.family: Design.fontText
            font.pixelSize: 11
            maximumLength: root.maximumLength
            selectByMouse: true
            clip: true
            onAccepted: root.accepted()
        }

        Text {
            anchors.fill: editor
            verticalAlignment: Text.AlignVCenter
            visible: editor.text.length === 0 && !editor.activeFocus
            text: root.placeholderText
            color: Design.textMuted
            font: editor.font
            elide: Text.ElideRight
        }

        TapHandler { onTapped: editor.forceActiveFocus() }
    }

    Text {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: field.bottom
        anchors.topMargin: 5
        visible: root.supportingText.length > 0
        text: root.supportingText
        color: root.invalid ? Design.red : Design.textMuted
        font.family: Design.fontText
        font.pixelSize: 9
        elide: Text.ElideRight
    }
}
