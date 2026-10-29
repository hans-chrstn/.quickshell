import QtQuick

FocusScope {
    id: root

    property string text: ""
    property string label: ""
    property string placeholderText: ""
    property string supportingText: ""
    property string leadingIcon: ""
    property bool invalid: false
    property bool readOnly: false
    property int maximumLength: 256
    signal accepted(string text)

    implicitWidth: 280
    implicitHeight: 88
    activeFocusOnTab: enabled
    opacity: enabled ? 1 : 0.38

    onActiveFocusChanged: {
        if (activeFocus && !editor.activeFocus && !clearButton.activeFocus)
            editor.forceActiveFocus();
    }

    Behavior on opacity {
        NumberAnimation {
            duration: 140
        }
    }

    Text {
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }
        text: root.label
        color: root.invalid ? "#ffff6259" : root.activeFocus ? "#d4d4d8" : "#8a8a92"
        elide: Text.ElideRight
        font.family: "SF Pro Text"
        font.pixelSize: 10
        font.weight: Font.Medium

        Behavior on color {
            ColorAnimation {
                duration: 120
            }
        }
    }

    Rectangle {
        id: field

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            topMargin: 18
        }
        height: 42
        radius: 13
        color: root.activeFocus ? "#12ffffff" : fieldHover.hovered ? "#0dffffff" : "#09ffffff"
        border.width: 1
        border.color: root.invalid ? "#bfff453a" : root.activeFocus ? "#78ffffff" : "#16ffffff"

        Behavior on color {
            ColorAnimation {
                duration: 120
            }
        }

        Behavior on border.color {
            ColorAnimation {
                duration: 120
            }
        }

        VisualLabControlGlyph {
            id: leadingGlyph

            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
                leftMargin: 12
            }
            width: 16
            height: 16
            visible: root.leadingIcon.length > 0
            iconKind: root.leadingIcon
            glyphColor: root.activeFocus ? "#d5d5da" : "#77777f"
        }

        TextInput {
            id: editor

            anchors {
                left: leadingGlyph.visible ? leadingGlyph.right : parent.left
                right: clearButton.visible ? clearButton.left : parent.right
                top: parent.top
                bottom: parent.bottom
                leftMargin: leadingGlyph.visible ? 9 : 13
                rightMargin: clearButton.visible ? 4 : 13
            }
            verticalAlignment: TextInput.AlignVCenter
            color: "#f0f0f2"
            selectionColor: "#b8ff9f0a"
            selectedTextColor: "#0a0a0c"
            maximumLength: root.maximumLength
            readOnly: root.readOnly
            selectByMouse: true
            clip: true
            text: root.text
            font.family: "SF Pro Text"
            font.pixelSize: 12
            onTextEdited: root.text = text
            onAccepted: root.accepted(root.text)
        }

        Text {
            anchors.fill: editor
            verticalAlignment: Text.AlignVCenter
            visible: editor.text.length === 0
            text: root.placeholderText
            color: "#686870"
            elide: Text.ElideRight
            font: editor.font
        }

        VisualLabGlyphButton {
            id: clearButton

            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
                rightMargin: 4
            }
            width: 32
            height: 32
            visible: root.enabled && !root.readOnly && root.text.length > 0
            toggleable: false
            iconKind: "close"
            onActivated: {
                root.text = "";
                editor.forceActiveFocus();
            }
        }

        HoverHandler {
            id: fieldHover
        }
    }

    Text {
        anchors {
            left: parent.left
            right: parent.right
            top: field.bottom
            topMargin: 6
        }
        text: root.supportingText
        color: root.invalid ? "#ffff6259" : "#707078"
        elide: Text.ElideRight
        font.family: "SF Pro Text"
        font.pixelSize: 9

        Behavior on color {
            ColorAnimation {
                duration: 120
            }
        }
    }
}
