import QtQuick
import qs.components
import qs.core

FocusScope {
    id: root

    property string text: ""
    property string label: ""
    property string placeholderText: ""
    property string supportingText: ""
    property string leadingGlyph: ""
    property bool invalid: false
    property bool readOnly: false
    property int maximumLength: 256
    signal accepted

    function forceEditorFocus() {
        editor.forceActiveFocus();
    }

    function selectAll() {
        editor.selectAll();
    }

    implicitWidth: 280
    implicitHeight: label.length > 0 || supportingText.length > 0 ? 84 : 42
    activeFocusOnTab: true
    opacity: enabled ? 1 : 0.38

    onActiveFocusChanged: {
        if (activeFocus && !editor.activeFocus && !clearButton.activeFocus)
            editor.forceActiveFocus();
    }

    Behavior on opacity {
        NumberAnimation {
            duration: Design.motionStateDuration
            easing.type: Design.motionStandardEasing
        }
    }

    Text {
        id: labelText

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        visible: root.label.length > 0
        text: root.label
        color: root.invalid ? Theme.statusDanger : root.activeFocus ? Theme.textSecondary : Theme.textTertiary
        font.family: Design.fontText
        font.pixelSize: Design.typeCaption
        font.weight: Font.Medium
        elide: Text.ElideRight

        Behavior on color {
            ColorAnimation {
                duration: Design.motionStateDuration
                easing.type: Design.motionStandardEasing
            }
        }
    }

    Rectangle {
        id: field

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: labelText.visible ? labelText.bottom : parent.top
        anchors.topMargin: labelText.visible ? 6 : 0
        height: 42
        radius: 13
        color: root.activeFocus ? Theme.interactionSelected : fieldHover.hovered ? Theme.interactionHover : Theme.surfaceGrouped
        border.width: 1
        border.color: root.invalid ? Theme.alpha(Theme.statusDanger, 0.75) : root.activeFocus ? Theme.focusRing : Theme.separator

        Behavior on color {
            ColorAnimation {
                duration: Design.motionStateDuration
                easing.type: Design.motionStandardEasing
            }
        }

        Behavior on border.color {
            ColorAnimation {
                duration: Design.motionStateDuration
                easing.type: Design.motionStandardEasing
            }
        }

        IslandGlyph {
            id: leadingIcon

            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            width: 16
            height: 16
            visible: root.leadingGlyph.length > 0
            name: root.leadingGlyph
            glyphColor: root.activeFocus ? Theme.textSecondary : Theme.textTertiary
        }

        TextInput {
            id: editor

            anchors.left: leadingIcon.visible ? leadingIcon.right : parent.left
            anchors.right: clearButton.visible ? clearButton.left : parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.leftMargin: leadingIcon.visible ? 9 : 13
            anchors.rightMargin: clearButton.visible ? 4 : 13
            verticalAlignment: TextInput.AlignVCenter
            color: Theme.textPrimary
            selectionColor: Theme.alpha(Theme.selection, 0.72)
            selectedTextColor: Theme.envelopeOpaque
            font.family: Design.fontText
            font.pixelSize: Design.typeBody
            maximumLength: root.maximumLength
            readOnly: root.readOnly
            selectByMouse: true
            clip: true
            text: root.text
            onTextEdited: root.text = text
            onAccepted: root.accepted()
        }

        Text {
            anchors.fill: editor
            verticalAlignment: Text.AlignVCenter
            visible: editor.text.length === 0
            text: root.placeholderText
            color: Theme.textTertiary
            font: editor.font
            elide: Text.ElideRight
        }

        GlyphButton {
            id: clearButton

            anchors.right: parent.right
            anchors.rightMargin: 5
            anchors.verticalCenter: parent.verticalCenter
            width: 32
            height: 32
            visible: root.enabled && !root.readOnly && root.text.length > 0
            glyph: "close"
            glyphSize: 13
            accessibleName: "Clear text"
            onActivated: {
                root.text = "";
                editor.forceActiveFocus();
            }
        }

        HoverHandler {
            id: fieldHover
        }

        TapHandler {
            enabled: root.enabled
            onTapped: editor.forceActiveFocus()
        }
    }

    Text {
        id: supportingLabel

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: field.bottom
        anchors.topMargin: 6
        visible: root.supportingText.length > 0
        text: root.supportingText
        color: root.invalid ? Theme.statusDanger : Theme.textTertiary
        font.family: Design.fontText
        font.pixelSize: 9
        elide: Text.ElideRight

        Behavior on color {
            ColorAnimation {
                duration: Design.motionStateDuration
                easing.type: Design.motionStandardEasing
            }
        }
    }
}
