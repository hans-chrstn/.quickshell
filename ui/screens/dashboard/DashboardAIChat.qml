import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.core
import qs.ui.shared

ColumnLayout {
    id: root

    anchors.fill: parent
    spacing: 8

    ListView {
        id: chatList
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 12
        clip: true
        model: AIManager.messages

        onCountChanged: Qt.callLater(function() {
            chatList.positionViewAtEnd()
        })

        delegate: RowLayout {
            width: chatList.width
            property bool isUser: model.role === "user"
            layoutDirection: isUser ? Qt.RightToLeft : Qt.LeftToRight

            Item {
                Layout.preferredWidth: messageBubble.width
                Layout.preferredHeight: messageBubble.height + (copyBtn.visible ? 22 : 0)
                Layout.alignment: isUser ? Qt.AlignRight : Qt.AlignLeft

                HoverHandler {
                    id: bubbleHover
                    enabled: !isUser
                }

                Rectangle {
                    id: messageBubble
                    width: Math.min(textLayout.implicitWidth + 32, chatList.width * 0.75)
                    height: textLayout.implicitHeight + 20
                    radius: 16
                    color: isUser ? ThemeManager.accentColor : "#1c1c1e"

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 1
                        radius: 15
                        color: isUser ? ThemeManager.accentColor : "#101012"
                        opacity: isUser ? 0.6 : 1.0
                    }

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 1
                        radius: 15
                        color: "transparent"
                        border.color: isUser ? Qt.lighter(ThemeManager.accentColor, 1.2) : ThemeManager.outlineStrongColor
                        border.width: 1
                    }

                    Text {
                        id: textLayout
                        x: 16
                        y: 10
                        width: messageBubble.width - 32
                        text: model.content
                        font.family: ThemeManager.fontFamily
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        color: isUser ? "#111111" : "#f5f5f7"
                        wrapMode: Text.WordWrap
                        textFormat: isUser ? Text.PlainText : Text.MarkdownText
                    }

                    BaseButton {
                        id: copyBtn
                        anchors.left: parent.left
                        anchors.leftMargin: 2
                        anchors.top: messageBubble.bottom
                        anchors.topMargin: -4
                        width: 28
                        height: 28
                        cornerRadius: 14
                        visible: !isUser
                        opacity: (bubbleHover.hovered || copyBtn.isHovered) ? 0.8 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 150 } }

                        onClicked: ClipboardManager.copyToClipboard(textLayout.text)

                        StyledLabel {
                            anchors.centerIn: parent
                            text: "󰆓"
                            type: "icon"
                            font.pixelSize: 10
                            opacity: 0.5
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                visible: true
            }
        }
    }

    Flow {
        Layout.fillWidth: true
        visible: AIManager.attachments.count > 0
        spacing: 6

        Repeater {
            model: AIManager.attachments

            delegate: Item {
                width: previewRow.implicitWidth + 16
                height: 32

                Rectangle {
                    anchors.fill: parent
                    radius: 10
                    color: "#1c1c1e"
                }

                RowLayout {
                    id: previewRow
                    anchors.centerIn: parent
                    spacing: 6

                    StyledLabel {
                        text: "󰈟"
                        type: "icon"
                        font.pixelSize: 12
                        opacity: 0.6
                    }

                    StyledLabel {
                        text: name
                        type: "caption"
                        font.pixelSize: 10
                        elideMode: Text.ElideRight
                        Layout.preferredWidth: Math.min(implicitWidth, 100)
                    }

                    BaseButton {
                        width: 18
                        height: 18
                        cornerRadius: 9

                        onClicked: AIManager.removeAttachment(index)

                        StyledLabel {
                            anchors.centerIn: parent
                            text: ThemeManager.iconClose
                            type: "icon"
                            font.pixelSize: 8
                            opacity: parent.isHovered ? 1.0 : 0.3
                        }
                    }
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        BaseButton {
            width: 36
            height: 36
            cornerRadius: 18

            onClicked: filePicker.active = true

            Rectangle {
                anchors.fill: parent
                radius: 18
                color: parent.isHovered ? ThemeManager.accentColor : "transparent"
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            StyledLabel {
                anchors.centerIn: parent
                text: "󰈟"
                type: "icon"
                font.pixelSize: 16
                customColor: parent.parent.isHovered ? "#111111" : ThemeManager.contentOnBackgroundColor
                opacity: parent.parent.isHovered ? 1.0 : 0.5
            }
        }

        StyledInput {
            id: messageInput
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            placeholder: "Ask anything..."
            enabled: !AIManager.isLoading

            onAccepted: {
                AIManager.sendMessage(text)
                text = ""
            }
        }

        BaseButton {
            width: 32
            height: 32
            cornerRadius: 16
            visible: messageInput.text.trim() !== "" && !AIManager.isLoading

            onClicked: {
                AIManager.sendMessage(messageInput.text)
                messageInput.text = ""
            }

            Rectangle {
                anchors.fill: parent
                radius: 16
                color: parent.isHovered ? ThemeManager.accentColor : "transparent"
                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
            }

            StyledLabel {
                anchors.centerIn: parent
                text: "󰁔"
                type: "icon"
                font.pixelSize: 14
                customColor: parent.parent.isHovered ? "#111111" : ThemeManager.accentColor
            }
        }

        StyledLabel {
            text: "󰛑"
            type: "icon"
            font.pixelSize: 16
            visible: AIManager.isLoading
            opacity: 0.6

            NumberAnimation on rotation {
                from: 0
                to: 360
                duration: 1200
                loops: Animation.Infinite
                running: AIManager.isLoading
            }
        }

        BaseButton {
            width: 32
            height: 32
            cornerRadius: 16
            visible: AIManager.messages.count >= 2 && !AIManager.isLoading && messageInput.text.trim() === ""

            onClicked: AIManager.regenerate()

            StyledLabel {
                anchors.centerIn: parent
                text: ThemeManager.iconRevert
                type: "icon"
                font.pixelSize: 12
                opacity: parent.isHovered ? 1.0 : 0.3
            }
        }
    }

    FilePicker {
        id: filePicker
        Layout.fillWidth: true
        Layout.fillHeight: true

        onFileSelected: (path) => {
            AIManager.addAttachment(path)
        }
    }
}
