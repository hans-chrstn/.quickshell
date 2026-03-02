import QtQuick
import QtQuick.Layouts
import qs.core
import qs.ui.shared

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
            anchors.leftMargin: 20
            anchors.rightMargin: 32
            anchors.topMargin: 20
            anchors.bottomMargin: 20
            spacing: 20

            RowLayout {
                Layout.fillWidth: true
                
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

            ListView {
                id: fileList
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: FileBrowserManager.fileModel
                clip: false
                spacing: 6

                delegate: NotesExplorerFileDelegate {
                    logic: root.logic
                    modelData: model
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8
                
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
                    modelData: model.modelData
                }
            }
        }
    }
}
