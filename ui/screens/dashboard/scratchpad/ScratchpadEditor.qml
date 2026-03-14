import QtQuick
import QtQuick.Layouts
import qs.core
import qs.ui.shared

StyledCard {
    id: root

    property bool active: false
    
    Layout.fillWidth: true
    Layout.fillHeight: true

    Flickable {
        anchors.fill: parent
        anchors.margins: 10
        contentWidth: {
            return parent.width - 20
        }
        contentHeight: {
            return scratchpadEdit.height
        }
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        TapHandler {
            onTapped: {
                scratchpadEdit.forceActiveFocus()
            }
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

            readonly property string savedContent: {
                if (!NotesManager) {
                    return ""
                }
                return NotesManager.scratchpadContent
            }
            
            text: savedContent

            onTextChanged: {
                if (focus && root.active && NotesManager) {
                    NotesManager.scratchpadContent = text
                }
            }

            Text {
                text: "Type something quick..."
                color: Qt.rgba(1, 1, 1, 0.2)
                font: scratchpadEdit.font
                visible: {
                    return scratchpadEdit.text === ""
                }
            }
        }
    }
}
