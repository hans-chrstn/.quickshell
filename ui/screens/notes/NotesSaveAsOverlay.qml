import QtQuick
import QtQuick.Layouts
import qs.core
import qs.ui.shared

Rectangle {
    id: root
    
    property var logic
    
    anchors.fill: parent
    color: Qt.rgba(0, 0, 0, 0.85)
    visible: logic.isSaveAsActive
    opacity: visible ? 1.0 : 0
    z: 100
    
    Behavior on opacity {
        NumberAnimation {
            duration: 200
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            logic.cancelSaveAs()
        }
    }

    Rectangle {
        width: 450
        height: 220
        anchors.centerIn: parent
        radius: 32
        color: ThemeManager.backgroundPrimaryColor
        border.color: ThemeManager.outlineStrongColor
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 32
            spacing: 20

            StyledLabel {
                text: "SAVE NOTE AS"
                type: "sidebarHeader"
                customColor: ThemeManager.accentColor
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                radius: 12
                color: ThemeManager.surfaceStrongColor
                border.color: ThemeManager.accentColor
                border.width: 1

                TextInput {
                    id: saveAsInput
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    verticalAlignment: TextInput.AlignVCenter
                    color: ThemeManager.surfaceContentColor
                    font.family: ThemeManager.fontFamily
                    font.pixelSize: 15
                    focus: root.visible
                    text: NotesManager.currentFilePath ? NotesManager.currentFilePath.split('/').pop() : "note.md"
                    
                    onAccepted: {
                        logic.executeSaveAs(text)
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                
                Item {
                    Layout.fillWidth: true
                }

                BaseButton {
                    width: 100
                    height: 36
                    onClicked: {
                        logic.cancelSaveAs()
                    }
                    
                    Rectangle {
                        anchors.fill: parent
                        radius: 10
                        color: ThemeManager.surfacePrimaryColor
                        
                        StyledLabel {
                            anchors.centerIn: parent
                            text: "CANCEL"
                            type: "caption"
                            customColor: ThemeManager.surfaceContentColor
                        }
                    }
                }

                BaseButton {
                    width: 100
                    height: 36
                    onClicked: {
                        saveAsInput.accepted()
                    }
                    
                    Rectangle {
                        anchors.fill: parent
                        radius: 10
                        color: ThemeManager.accentColor
                        
                        StyledLabel {
                            anchors.centerIn: parent
                            text: "SAVE"
                            type: "caption"
                            customColor: ThemeManager.contentPrimaryColor
                            font.weight: Font.Black
                        }
                    }
                }
            }
        }
    }
}
