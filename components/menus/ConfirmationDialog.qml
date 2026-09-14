import QtQuick
import QtQuick.Controls
import qs.core
import qs.components.menus

Dialog {
    id: root

    property string message: ""
    property string confirmLabel: "Remove"
    property bool destructive: true
    property int currentIndex: 0

    parent: Overlay.overlay
    width: Math.min(360, Math.max(0, (parent?.width ?? 376) - 16))
    x: parent ? (parent.width - width) / 2 : 0
    y: parent ? Math.max(8, (parent.height - implicitHeight) / 2) : 0
    padding: 16
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    header: null
    footer: null
    onAboutToShow: currentIndex = 0
    onOpened: contentItem.forceActiveFocus()

    background: Rectangle {
        radius: 18
        color: Design.surfaceRaised
        border.width: 1
        border.color: Design.glassStroke
    }

    contentItem: Column {
        spacing: 12
        focus: true

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Left || event.key === Qt.Key_Right
                    || event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                root.currentIndex = 1 - root.currentIndex;
                event.accepted = true;
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                    || event.key === Qt.Key_Space) {
                if (root.currentIndex === 1) root.accept();
                else root.reject();
                event.accepted = true;
            }
        }

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
            text: root.message
            textFormat: Text.PlainText
            wrapMode: Text.Wrap
            color: Design.textMuted
            font.family: Design.fontText
            font.pixelSize: 12
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
                objectName: "confirmationCancel"
                width: (parent.width - parent.spacing) / 2
                action: ({ label: "Cancel" })
                highlighted: root.currentIndex === 0
                onHovered: root.currentIndex = 0
                onTriggered: root.reject()
            }

            ContextMenuItem {
                objectName: "confirmationAccept"
                width: (parent.width - parent.spacing) / 2
                action: ({ label: root.confirmLabel, destructive: root.destructive })
                highlighted: root.currentIndex === 1
                onHovered: root.currentIndex = 1
                onTriggered: root.accept()
            }
        }
    }
}
