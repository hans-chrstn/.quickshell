import QtQuick
import QtQuick.Controls
import qs.components.input
import qs.components.menus
import qs.core

Dialog {
    id: root

    property string message: ""
    property string fieldLabel: ""
    property string placeholderText: ""
    property string confirmLabel: "Save"
    property int maximumLength: 256
    property var validator: value => ""
    property var submitHandler: value => ({
                accepted: true
            })
    property int currentIndex: 1
    property string validationMessage: ""
    signal submitted(string value)

    function openWith(value) {
        validationMessage = "";
        entry.text = String(value || "");
        open();
    }

    function submit() {
        const value = entry.text.trim();
        const validation = String(validator ? validator(value) || "" : "");
        if (validation.length > 0) {
            validationMessage = validation;
            entry.forceEditorFocus();
            return false;
        }
        const result = submitHandler ? submitHandler(value) : ({
                accepted: true
            });
        if (result !== true && result?.accepted !== true) {
            validationMessage = String(result?.message || "The value could not be saved.");
            entry.forceEditorFocus();
            return false;
        }
        submitted(value);
        accept();
        return true;
    }

    parent: Overlay.overlay
    width: Math.min(380, Math.max(0, (parent?.width ?? 396) - 16))
    x: parent ? (parent.width - width) / 2 : 0
    y: parent ? Math.max(8, (parent.height - implicitHeight) / 2) : 0
    padding: 16
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    header: null
    footer: null
    onAboutToShow: {
        currentIndex = 1;
        validationMessage = "";
    }
    onOpened: Qt.callLater(() => {
        entry.forceEditorFocus();
        entry.selectAll();
    })

    background: Rectangle {
        radius: 18
        color: Design.surfaceRaised
        border.width: 1
        border.color: Design.glassStroke
    }

    contentItem: Column {
        spacing: 12

        Text {
            width: parent.width
            text: root.title
            textFormat: Text.PlainText
            wrapMode: Text.Wrap
            color: Design.text
            font.family: Design.fontText
            font.pixelSize: 15
            font.weight: Font.DemiBold
        }

        Text {
            width: parent.width
            visible: root.message.length > 0
            text: root.message
            textFormat: Text.PlainText
            wrapMode: Text.Wrap
            color: Design.textMuted
            font.family: Design.fontText
            font.pixelSize: 12
        }

        DecoratedTextField {
            id: entry
            width: parent.width
            label: root.fieldLabel
            placeholderText: root.placeholderText
            maximumLength: root.maximumLength
            invalid: root.validationMessage.length > 0
            supportingText: root.validationMessage
            onAccepted: root.submit()
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Design.separator
        }

        Row {
            width: parent.width
            spacing: 8

            ContextMenuItem {
                width: (parent.width - parent.spacing) / 2
                action: ({
                        label: "Cancel"
                    })
                highlighted: root.currentIndex === 0
                onHovered: root.currentIndex = 0
                onTriggered: root.reject()
            }

            ContextMenuItem {
                width: (parent.width - parent.spacing) / 2
                action: ({
                        label: root.confirmLabel
                    })
                highlighted: root.currentIndex === 1
                onHovered: root.currentIndex = 1
                onTriggered: root.submit()
            }
        }
    }
}
