import QtQuick
import QtQuick.Layouts
import qs.core
import qs.ui.shared

ColumnLayout {
    id: root

    property bool active: false

    anchors.fill: parent
    anchors.margins: 20
    spacing: 12

    StyledLabel {
        text: "AI Chat"
        type: "heading"
        font.pixelSize: 28
    }

    StyledLabel {
        text: "Powered by DeepSeek"
        type: "caption"
        opacity: 0.3
    }

    ListView {
        id: chatList
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 12
        clip: true
        model: AIManager.messages

        onCountChanged: {
            Qt.callLater(function() {
                chatList.positionViewAtEnd()
            })
        }

        delegate: RowLayout {
            width: chatList.width
            property bool isUser: model.role === "user"
            layoutDirection: isUser ? Qt.RightToLeft : Qt.LeftToRight

            Item {
                Layout.preferredWidth: Math.min(messageBubble.implicitWidth + 28, chatList.width * 0.8)
                Layout.preferredHeight: messageBubble.implicitHeight + 20

                Rectangle {
                    id: messageBubble
                    anchors.right: isUser ? parent.right : undefined
                    anchors.left: isUser ? undefined : parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(textLayout.implicitWidth + 28, parent.width)
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

                    StyledLabel {
                        id: textLayout
                        anchors.centerIn: parent
                        width: parent.width - 28
                        text: model.content
                        type: "body"
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        customColor: isUser ? "#111111" : "#f5f5f7"
                        wrapMode: Text.WordWrap
                    }
                }
            }

            Item { Layout.fillWidth: true; visible: isUser }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        BaseButton {
            width: 36
            height: 36
            cornerRadius: 18
            visible: AIManager.messages.count > 0 && !AIManager.isLoading

            onClicked: AIManager.clearChat()

            StyledLabel {
                anchors.centerIn: parent
                text: ThemeManager.iconTrash
                type: "icon"
                font.pixelSize: 14
                opacity: parent.isHovered ? 1.0 : 0.4
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 44

            Rectangle {
                anchors.fill: parent
                radius: 22
                color: "#1c1c1e"
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                radius: 21
                color: "#101012"
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                radius: 21
                color: "transparent"
                border.color: ThemeManager.outlineStrongColor
                border.width: 1
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 18
                anchors.rightMargin: 8
                spacing: 8

                TextInput {
                    id: messageInput
                    Layout.fillWidth: true
                    color: "#f5f5f7"
                    font.family: ThemeManager.fontFamily
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    enabled: !AIManager.isLoading

                    onAccepted: {
                        AIManager.sendMessage(text)
                        text = ""
                    }

                    StyledLabel {
                        text: "Ask anything..."
                        type: "body"
                        font.pixelSize: 14
                        font.weight: Font.Medium
                        opacity: 0.15
                        visible: !messageInput.text && !messageInput.activeFocus
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
                        Behavior on color { ColorAnimation { duration: 150 } }
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
        }
    }
}
