import QtQuick
import QtQuick.Layouts
import qs.core
import qs.ui.shared

Rectangle {
    id: root

    property var logic
    
    Layout.fillWidth: true
    Layout.preferredHeight: 80
    color: "transparent"

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 32
        anchors.rightMargin: 32
        spacing: 20

        BaseButton {
            width: 32
            height: 32
            onClicked: {
                logic.toggleExplorer()
            }
            
            StyledLabel {
                anchors.centerIn: parent
                text: logic.isExplorerExpanded ? "󰍜" : "󰍟"
                type: "icon"
                customColor: ThemeManager.accentColor
            }
        }

        BaseButton {
            id: titleBtn
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            onClicked: {
                logic.startSaveAs()
            }
            
            ColumnLayout {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                
                StyledLabel {
                    text: NotesManager.currentFilePath ? NotesManager.currentFilePath.split('/').pop() : "NEW DOCUMENT"
                    type: "title"
                    font.weight: Font.Black
                    customColor: titleBtn.isHovered ? ThemeManager.accentColor : ThemeManager.surfaceContentColor
                }
                
                StyledLabel {
                    text: NotesManager.hasUnsavedChanges ? "UNSAVED CHANGES" : "AUTOSAVED"
                    type: "caption"
                    font.weight: Font.Black
                    customColor: NotesManager.hasUnsavedChanges ? ThemeManager.dangerColor : ThemeManager.accentColor
                    letterSpacing: 1
                }
            }
            
            HoverHandler {
                cursorShape: Qt.PointingHandCursor
            }
        }

        Item {
            Layout.fillWidth: true
        }

        Row {
            spacing: 12
            
            BaseButton {
                width: 40
                height: 40
                onClicked: {
                    NotesManager.createNewNote()
                }
                
                Rectangle {
                    anchors.fill: parent
                    radius: 20
                    color: parent.isHovered ? ThemeManager.surfacePrimaryColor : "transparent"
                    
                    StyledLabel {
                        anchors.centerIn: parent
                        text: "󰐕"
                        type: "icon"
                        customColor: ThemeManager.surfaceContentColor
                    }
                }
            }

            BaseButton {
                width: 40
                height: 40
                onClicked: {
                    logic.startSaveAs()
                }
                
                Rectangle {
                    anchors.fill: parent
                    radius: 20
                    color: parent.isHovered ? ThemeManager.surfacePrimaryColor : "transparent"
                    
                    StyledLabel {
                        anchors.centerIn: parent
                        text: "󰆓"
                        type: "icon"
                        customColor: ThemeManager.surfaceContentColor
                    }
                }
            }

            Rectangle {
                width: 140
                height: 32
                radius: 16
                color: ThemeManager.surfacePrimaryColor
                Layout.alignment: Qt.AlignVCenter
                
                Row {
                    anchors.fill: parent
                    anchors.margins: 2
                    
                    Repeater {
                        model: ["EDIT", "VIEW"]
                        delegate: BaseButton {
                            width: 68
                            height: 28
                            onClicked: {
                                logic.isPreviewMode = (modelData === "VIEW")
                            }
                            
                            Rectangle {
                                anchors.fill: parent
                                radius: 14
                                color: (logic.isPreviewMode === (modelData === "VIEW")) ? ThemeManager.accentColor : "transparent"
                                
                                StyledLabel {
                                    anchors.centerIn: parent
                                    text: modelData
                                    type: "caption"
                                    font.weight: Font.Black
                                    customColor: (logic.isPreviewMode === (modelData === "VIEW")) ? ThemeManager.contentPrimaryColor : ThemeManager.surfaceContentColor
                                }
                            }
                        }
                    }
                }
            }
        }

        BaseButton {
            width: 36
            height: 36
            onClicked: {
                ViewManager.closeWindowByType("notes")
            }
            
            Rectangle {
                anchors.fill: parent
                radius: 18
                color: ThemeManager.surfacePrimaryColor
                
                StyledLabel {
                    anchors.centerIn: parent
                    text: "󰅖"
                    type: "icon"
                    customColor: ThemeManager.surfaceContentColor
                }
            }
        }
    }
}
