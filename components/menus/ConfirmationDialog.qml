import QtQuick
import qs.core
import qs.components.menus

ModalDialog {
    id: root

    property string message: ""
    property string confirmLabel: "Remove"
    property bool destructive: true
    property int currentIndex: 0

    onAboutToShow: currentIndex = 0
    onOpened: contentItem.forceActiveFocus()

    contentItem: Column {
        spacing: 12
        focus: true

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Left || event.key === Qt.Key_Right || event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                root.currentIndex = 1 - root.currentIndex;
                event.accepted = true;
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                if (root.currentIndex === 1)
                    root.accept();
                else
                    root.reject();
                event.accepted = true;
            }
        }

        Text {
            width: parent.width
            text: root.title
            textFormat: Text.PlainText
            wrapMode: Text.Wrap
            color: Theme.textPrimary
            font.family: Design.fontText
            font.pixelSize: 15
            font.weight: Font.DemiBold
        }

        Text {
            width: parent.width
            text: root.message
            textFormat: Text.PlainText
            wrapMode: Text.Wrap
            color: Theme.textSecondary
            font.family: Design.fontText
            font.pixelSize: 12
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.separator
        }

        Row {
            width: parent.width
            spacing: 8

            ContextMenuItem {
                objectName: "confirmationCancel"
                width: (parent.width - parent.spacing) / 2
                action: ({
                        label: "Cancel"
                    })
                highlighted: root.currentIndex === 0
                onHovered: root.currentIndex = 0
                onTriggered: root.reject()
            }

            ContextMenuItem {
                objectName: "confirmationAccept"
                width: (parent.width - parent.spacing) / 2
                action: ({
                        label: root.confirmLabel,
                        destructive: root.destructive
                    })
                highlighted: root.currentIndex === 1
                onHovered: root.currentIndex = 1
                onTriggered: root.accept()
            }
        }
    }
}
