import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import qs.core
import qs.ui.shared

Rectangle {
    id: root
    property bool active: false
    anchors {
        fill: parent
    }
    color: Qt.rgba(0, 0, 0, 0.8)
    visible: active
    opacity: active ? 1 : 0
    z: 2000
    
    Behavior on opacity { 
        NumberAnimation { 
            duration: 300 
        } 
    }

    property bool showAddMenu: false

    MouseArea {
        anchors {
            fill: parent
        }
        onClicked: {
            root.active = false
            root.showAddMenu = false
        }
    }

    Rectangle {
        anchors {
            centerIn: parent
        }
        width: 450
        height: 550
        color: Qt.rgba(0, 0, 0, 0.9)
        border {
            color: ThemeManager.outlinePrimaryColor
            width: 1
        }

        Rectangle { 
            width: 15
            height: 2
            color: ThemeManager.accentColor
            anchors {
                top: parent.top
                left: parent.left
            }
        }

        Rectangle { 
            width: 2
            height: 15
            color: ThemeManager.accentColor
            anchors {
                top: parent.top
                left: parent.left
            }
        }

        Rectangle { 
            width: 15
            height: 2
            color: ThemeManager.accentColor
            anchors {
                bottom: parent.bottom
                right: parent.right
            }
        }

        Rectangle { 
            width: 2
            height: 15
            color: ThemeManager.accentColor
            anchors {
                bottom: parent.bottom
                right: parent.right
            }
        }

        ColumnLayout {
            anchors {
                fill: parent
                margins: 30
            }
            spacing: 20

            Column {
                Layout.fillWidth: true
                StyledLabel {
                    text: "HANDSHAKE_SELECTION_PROTOCOL //"
                    font {
                        pixelSize: 10
                        weight: Font.Black
                    }
                    opacity: 0.5
                }
                StyledLabel {
                    text: "ENVIRONMENT_ACCESS_POINT"
                    font {
                        pixelSize: 18
                        weight: Font.Bold
                        letterSpacing: 2
                    }
                    customColor: ThemeManager.accentColor
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                visible: root.showAddMenu
                spacing: 15

                Rectangle {
                    Layout.fillWidth: true
                    height: 120
                    color: Qt.rgba(1, 1, 1, 0.05)
                    border {
                        color: ThemeManager.outlineVariantColor
                        width: 1
                    }

                    ColumnLayout {
                        anchors {
                            fill: parent
                            margins: 15
                        }
                        spacing: 10

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10
                            StyledLabel { 
                                text: "NAME //"
                                font {
                                    pixelSize: 8
                                }
                                opacity: 0.5
                                Layout.preferredWidth: 60 
                            }
                            TextField {
                                id: newNameInput
                                Layout.fillWidth: true
                                placeholderText: "ID_NAME..."
                                color: "white"
                                background: Rectangle { 
                                    color: "black"
                                    opacity: 0.5
                                    border {
                                        color: parent.activeFocus ? ThemeManager.accentColor : ThemeManager.outlinePrimaryColor
                                        width: 1
                                    }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10
                            StyledLabel { 
                                text: "EXEC //"
                                font {
                                    pixelSize: 8
                                }
                                opacity: 0.5
                                Layout.preferredWidth: 60 
                            }
                            TextField {
                                id: newExecInput
                                Layout.fillWidth: true
                                placeholderText: "SHELL_EXEC..."
                                color: "white"
                                background: Rectangle { 
                                    color: "black"
                                    opacity: 0.5
                                    border {
                                        color: parent.activeFocus ? ThemeManager.accentColor : ThemeManager.outlinePrimaryColor
                                        width: 1
                                    }
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.alignment: Qt.AlignRight
                    spacing: 10
                    BaseButton {
                        width: 100
                        height: 30
                        onClicked: {
                            root.showAddMenu = false
                        }
                        Rectangle { 
                            anchors {
                                fill: parent
                            }
                            color: "transparent"
                            border { 
                                color: ThemeManager.outlinePrimaryColor
                                width: 1 
                            }
                            StyledLabel { 
                                anchors {
                                    centerIn: parent
                                }
                                text: "CANCEL"
                                font { 
                                    pixelSize: 9
                                    weight: Font.Bold 
                                } 
                            }
                        }
                    }
                    BaseButton {
                        width: 140
                        height: 30
                        onClicked: {
                            if (newNameInput.text !== "" && newExecInput.text !== "") {
                                SessionManager.addSession(newNameInput.text, newExecInput.text)
                                newNameInput.text = ""
                                newExecInput.text = ""
                                root.showAddMenu = false
                            }
                        }
                        Rectangle { 
                            anchors {
                                fill: parent
                            }
                            color: ThemeManager.accentColor
                            StyledLabel { 
                                anchors {
                                    centerIn: parent
                                }
                                text: "INITIATE_ENTRY"
                                font { 
                                    pixelSize: 9
                                    weight: Font.Black 
                                }
                                customColor: "black" 
                            }
                        }
                    }
                }
            }

            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: SessionManager.model
                spacing: 10
                clip: false
                visible: !root.showAddMenu

                delegate: Item {
                    width: parent ? parent.width : 390
                    height: 50

                    BaseButton {
                        id: sessionBtn
                        anchors {
                            fill: parent
                        }
                        onClicked: {
                            SessionManager.selectSession(index)
                            root.active = false
                        }

                        Rectangle {
                            anchors {
                                fill: parent
                            }
                            color: {
                                if (SessionManager.currentSessionName === model.name) {
                                    return Qt.rgba(ThemeManager.accentColor.r, ThemeManager.accentColor.g, ThemeManager.accentColor.b, 0.15)
                                }
                                return Qt.rgba(1, 1, 1, 0.03)
                            }
                            border {
                                color: SessionManager.currentSessionName === model.name ? ThemeManager.accentColor : ThemeManager.outlineVariantColor
                                width: 1
                            }
                            
                            scale: sessionBtn.isHovered ? 1.02 : 1.0
                            Behavior on scale { 
                                NumberAnimation { 
                                    duration: 200 
                                } 
                            }

                            RowLayout {
                                anchors {
                                    fill: parent
                                    margins: 12
                                }
                                spacing: 15

                                StyledLabel {
                                    text: "󰊠"
                                    font { 
                                        pixelSize: 20 
                                    }
                                    customColor: SessionManager.currentSessionName === model.name ? ThemeManager.accentColor : ThemeManager.surfaceContentColor
                                }

                                Column {
                                    Layout.fillWidth: true
                                    StyledLabel { 
                                        text: model.name.toUpperCase()
                                        font { 
                                            pixelSize: 14
                                            weight: Font.Black 
                                        }
                                        customColor: SessionManager.currentSessionName === model.name ? "white" : ThemeManager.surfaceContentColor
                                    }
                                    StyledLabel {
                                        text: model.exec
                                        font { 
                                            pixelSize: 8
                                            family: "monospace" 
                                        }
                                        opacity: 0.4
                                    }
                                }

                                BaseButton {
                                    id: delBtn
                                    width: 30
                                    height: 30
                                    onClicked: {
                                        SessionManager.deleteSession(index)
                                    }
                                    visible: sessionBtn.isHovered
                                    
                                    StyledLabel {
                                        anchors {
                                            centerIn: parent
                                        }
                                        text: "󰅖"
                                        font {
                                            pixelSize: 14
                                        }
                                        customColor: delBtn.isHovered ? ThemeManager.dangerColor : ThemeManager.surfaceContentColor
                                        opacity: delBtn.isHovered ? 1.0 : 0.5
                                    }
                                }

                                StyledLabel {
                                    text: "ACTIVE"
                                    font { 
                                        pixelSize: 8
                                        weight: Font.Black 
                                    }
                                    customColor: ThemeManager.accentColor
                                    visible: SessionManager.currentSessionName === model.name
                                }
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 15
                visible: !root.showAddMenu

                BaseButton {
                    id: addBtn
                    Layout.fillWidth: true
                    height: 40
                    onClicked: {
                        root.showAddMenu = true
                    }
                    Rectangle {
                        anchors {
                            fill: parent
                        }
                        color: "transparent"
                        border { 
                            color: ThemeManager.accentColor
                            width: 1 
                        }
                        RowLayout {
                            anchors {
                                centerIn: parent
                            }
                            spacing: 10
                            StyledLabel { 
                                text: "󰐕"
                                customColor: ThemeManager.accentColor 
                            }
                            StyledLabel { 
                                text: "REGISTER_NEW_NODE"
                                font { 
                                    pixelSize: 9
                                    weight: Font.Black 
                                }
                                customColor: ThemeManager.accentColor 
                            }
                        }
                    }
                }

                BaseButton {
                    id: resetBtn
                    width: 40
                    height: 40
                    onClicked: {
                        SessionManager.resetToDefaults()
                    }
                    Rectangle {
                        anchors {
                            fill: parent
                        }
                        color: "transparent"
                        border { 
                            color: ThemeManager.outlinePrimaryColor
                            width: 1 
                        }
                        StyledLabel { 
                            anchors {
                                centerIn: parent
                            }
                            text: "󰕌"
                            font {
                                pixelSize: 16
                            }
                        }
                    }
                }

                BaseButton {
                    id: closeBtn
                    width: 80
                    height: 40
                    onClicked: {
                        root.active = false
                    }
                    Rectangle {
                        anchors {
                            fill: parent
                        }
                        color: "transparent"
                        border { 
                            color: ThemeManager.outlinePrimaryColor
                            width: 1 
                        }
                        StyledLabel { 
                            anchors {
                                centerIn: parent
                            }
                            text: "EXIT"
                            font { 
                                pixelSize: 9
                                weight: Font.Bold 
                            }
                        }
                    }
                }
            }
        }
    }
}
