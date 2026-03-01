import QtQuick
import QtQuick.Layouts
import qs.core
import qs.ui.shared

Rectangle {
    id: root

    property var logic
    anchors.fill: parent
    color: Qt.rgba(0, 0, 0, 0.95)
    visible: logic.showSessionPicker
    opacity: visible ? 1 : 0
    
    Behavior on opacity {
        NumberAnimation {
            duration: 300
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            logic.showSessionPicker = false
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 30

        StyledLabel {
            Layout.alignment: Qt.AlignHCenter
            text: "SESSION MANAGEMENT"
            type: "title"
            customColor: ColorManager.accentColor
            font.weight: Font.Black
            font.letterSpacing: 3
            font.pixelSize: 16
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 10

            GreeterSessionPickerInput { }
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 10

            Repeater {
                model: SessionManager.model
                delegate: GreeterSessionPickerItem {
                    logic: root.logic
                    sessionIndex: index
                    sessionName: name
                    sessionExec: exec
                }
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 20
            
            BaseButton {
                id: resetSessionsBtn
                width: 180
                height: 36
                onClicked: {
                    SessionManager.resetToDefaults()
                }
                
                Rectangle {
                    anchors.fill: parent
                    radius: 18
                    color: "transparent"
                    border.color: Qt.rgba(1, 1, 1, 0.2)
                    scale: resetSessionsBtn.isHovered ? 1.05 : 1.0
                    
                    Behavior on scale {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutQuart
                        }
                    }
                    
                    StyledLabel {
                        anchors.centerIn: parent
                        text: "RESET TO DEFAULTS"
                        type: "caption"
                        font.weight: Font.Bold
                        font.pixelSize: 10
                    }
                }
            }
            
            BaseButton {
                id: closePickerBtn
                width: 100
                height: 36
                onClicked: {
                    logic.showSessionPicker = false
                }
                
                Rectangle {
                    anchors.fill: parent
                    radius: 18
                    color: "transparent"
                    border.color: Qt.rgba(1, 1, 1, 0.2)
                    scale: closePickerBtn.isHovered ? 1.05 : 1.0
                    
                    Behavior on scale {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutQuart
                        }
                    }
                    
                    StyledLabel {
                        anchors.centerIn: parent
                        text: "CLOSE"
                        type: "caption"
                        font.weight: Font.Bold
                        font.pixelSize: 10
                    }
                }
            }
        }
    }
}
