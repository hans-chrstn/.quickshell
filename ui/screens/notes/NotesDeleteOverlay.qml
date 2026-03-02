import QtQuick
import QtQuick.Layouts
import qs.core
import qs.ui.shared

Rectangle {
    id: root
    
    property var logic
    
    anchors.fill: parent
    color: Qt.rgba(0, 0, 0, 0.85)
    visible: logic.pendingDeletePath !== ""
    opacity: visible ? 1.0 : 0
    z: 110
    
    Behavior on opacity {
        NumberAnimation {
            duration: 200
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            logic.cancelDelete()
        }
    }

    Rectangle {
        width: 450
        height: 200
        anchors.centerIn: parent
        radius: 32
        color: ThemeManager.backgroundPrimaryColor
        border.color: ThemeManager.dangerColor
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 32
            spacing: 20

            StyledLabel {
                text: "DELETE FILE?"
                type: "sidebarHeader"
                customColor: ThemeManager.dangerColor
            }

            StyledLabel {
                text: "Are you sure you want to permanently delete
" + logic.pendingDeletePath.split('/').pop() + "?"
                type: "body"
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
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
                        logic.cancelDelete()
                    }
                    
                    Rectangle {
                        anchors.fill: parent
                        radius: 10
                        color: ThemeManager.surfacePrimaryColor
                        
                        StyledLabel {
                            anchors.centerIn: parent
                            text: "CANCEL"
                            type: "caption"
                        }
                    }
                }

                BaseButton {
                    width: 100
                    height: 36
                    onClicked: {
                        logic.executeDelete()
                    }
                    
                    Rectangle {
                        anchors.fill: parent
                        radius: 10
                        color: ThemeManager.dangerColor
                        
                        StyledLabel {
                            anchors.centerIn: parent
                            text: "DELETE"
                            type: "caption"
                            customColor: ThemeManager.contentOnBackgroundColor
                            font.weight: Font.Black
                        }
                    }
                }
            }
        }
    }
}
