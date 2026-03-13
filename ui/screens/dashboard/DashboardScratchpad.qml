import QtQuick
import QtQuick.Layouts
import qs.core
import qs.ui.shared

ColumnLayout {
    anchors.fill: parent
    anchors.margins: 30
    spacing: 25

    StyledLabel {
        text: "Scratchpad"
        type: "heading"
        font.pixelSize: 28
    }

    StyledCard {
        Layout.fillWidth: true
        Layout.fillHeight: true

        Flickable {
            anchors.fill: parent
            anchors.margins: 10
            contentWidth: parent.width - 20
            contentHeight: scratchpadEdit.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            TapHandler {
                onTapped: scratchpadEdit.forceActiveFocus()
            }

            TextEdit {
                id: scratchpadEdit
                width: parent.width
                wrapMode: TextEdit.Wrap
                color: ThemeManager.contentOnBackgroundColor
                selectionColor: ThemeManager.accentColor
                selectedTextColor: ThemeManager.contentPrimaryColor
                font.pixelSize: 14
                font.family: ThemeManager.fontFamily

                readonly property string savedContent: NotesManager.scratchpadContent
                text: savedContent

                onTextChanged: {
                    if (focus && DashboardManager.active) {
                        NotesManager.scratchpadContent = text
                    }
                }

                Text {
                    text: "Type something quick..."
                    color: Qt.rgba(1, 1, 1, 0.2)
                    font: scratchpadEdit.font
                    visible: scratchpadEdit.text === ""
                }
            }
        }
    }

    Item { Layout.fillHeight: true }
}
