import QtQuick
import QtQuick.Layouts
import qs.core
import qs.ui.shared
import qs.shared

Rectangle {
    id: root

    property var logic
    
    Layout.preferredWidth: logic.isExplorerExpanded ? 280 : 0
    Layout.fillHeight: true
    color: ThemeManager.surfaceSubtleColor
    clip: true

    Behavior on Layout.preferredWidth {
        NumberAnimation {
            duration: 400
            easing.type: Easing.OutQuart
        }
    }

    Item {
        width: 280
        height: root.height

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: 24
            anchors.rightMargin: 24
            anchors.topMargin: 20
            anchors.bottomMargin: 20
            spacing: 20

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 4
                Layout.rightMargin: 4
                
                StyledLabel {
                    text: "EXPLORER"
                    type: "caption"
                    customColor: ThemeManager.surfaceContentColor
                    font.weight: Font.Black
                    letterSpacing: 2
                    opacity: 0.5
                    Layout.fillWidth: true
                }
                
                BaseButton {
                    width: 24
                    height: 24
                    onClicked: {
                        FileBrowserManager.navigateToParent()
                    }
                    
                    StyledLabel {
                        anchors.centerIn: parent
                        text: "󰁝"
                        type: "icon"
                        font.pixelSize: 14
                        customColor: ThemeManager.accentColor
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                radius: 18
                color: ThemeManager.surfaceStrongColor
                border.color: ThemeManager.outlinePrimaryColor
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8

                    StyledLabel {
                        text: ThemeManager.iconSearch
                        type: "caption"
                        font.pixelSize: 14
                        opacity: noteSearchInput.activeFocus ? 1.0 : 0.3
                        customColor: ThemeManager.accentColor
                    }

                    TextInput {
                        id: noteSearchInput
                        Layout.fillWidth: true
                        color: ThemeManager.contentOnBackgroundColor
                        font.family: ThemeManager.fontFamily
                        font.pixelSize: 12
                        selectionColor: ThemeManager.accentColor
                        text: NotesManager.searchText
                        
                        onTextChanged: {
                            NotesManager.searchText = text
                        }

                        StyledLabel {
                            text: "Search notes..."
                            type: "caption"
                            font.pixelSize: 12
                            opacity: 0.2
                            visible: !noteSearchInput.text && !noteSearchInput.activeFocus
                        }
                    }
                }
            }

            ListView {
                id: fileList
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: FileBrowserManager.fileModel
                clip: false
                spacing: 6

                delegate: NotesExplorerFileDelegate {
                    logic: root.logic
                    
                    visible: {
                        let itemName = model ? model.name : ""
                        if (!NotesManager.searchText || NotesManager.searchText === "" || !itemName) {
                            return true
                        }
                        return FuzzySearch.score(NotesManager.searchText, itemName) > 0
                    }
                    
                    height: visible ? 38 : 0
                    
                    Behavior on height {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutQuart
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8
                Layout.leftMargin: 4
                Layout.rightMargin: 4
                
                StyledLabel {
                    text: "RECENT NOTES"
                    type: "caption"
                    customColor: ThemeManager.surfaceContentColor
                    font.weight: Font.Black
                    letterSpacing: 2
                    opacity: 0.5
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: ThemeManager.surfaceContentColor
                    opacity: 0.1
                }
            }

            ListView {
                id: recentList
                Layout.preferredHeight: 180
                Layout.fillWidth: true
                model: NotesManager.recentFiles
                clip: false
                spacing: 4
                
                delegate: NotesExplorerRecentDelegate {
                    notePath: modelData
                }
            }
        }
    }
}
