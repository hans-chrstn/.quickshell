import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.core
import qs.ui.shared

Item {
    id: root

    property var logic
    
    Layout.fillWidth: true
    Layout.fillHeight: true

    ScrollView {
        id: notesScroll
        anchors.fill: parent
        clip: true
        background: null

        Loader {
            id: contentLoader
            width: notesScroll.availableWidth
            sourceComponent: logic.isPreviewMode ? previewComp : editorComp
        }

        Component {
            id: editorComp
            
            TextArea {
                width: notesScroll.availableWidth
                text: NotesManager.content
                wrapMode: TextEdit.Wrap
                color: ThemeManager.surfaceContentColor
                font.family: ThemeManager.fontFamily
                font.pixelSize: 16
                topPadding: 40
                leftPadding: 40
                rightPadding: 40
                bottomPadding: 40
                
                onTextEdited: {
                    NotesManager.content = text
                }
                
                selectionColor: ThemeManager.accentColor
                selectedTextColor: ThemeManager.contentPrimaryColor
                background: null
                
                Component.onCompleted: {
                    forceActiveFocus()
                }
            }
        }

        Component {
            id: previewComp
            
            Text {
                width: notesScroll.availableWidth
                padding: 40
                text: NotesManager.content
                textFormat: Text.MarkdownText
                wrapMode: Text.Wrap
                color: ThemeManager.surfaceContentColor
                font.family: ThemeManager.fontFamily
                font.pixelSize: 16
                linkColor: ThemeManager.accentColor
                
                onLinkActivated: (link) => {
                    Quickshell.execDetached(["xdg-open", link])
                }
            }
        }
    }
}
