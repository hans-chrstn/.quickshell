import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.core
import qs.ui.shared

ColumnLayout {
    id: root

    anchors.fill: parent
    spacing: 8

    StyledLabel {
        text: "Chat History"
        type: "title"
        letterSpacing: -0.35
        Layout.fillWidth: true
    }

    StyledLabel {
        text: AIManager.sessions.count + " saved chat(s)"
        type: "caption"
        opacity: 0.3
        Layout.fillWidth: true
        visible: AIManager.sessions.count > 0
    }

    ListView {
        id: historyList
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 6
        clip: true
        model: AIManager.sessions

        delegate: Item {
            width: historyList.width
            height: 56

            Rectangle {
                anchors.fill: parent
                radius: 16
                color: "#1c1c1e"
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                radius: 15
                color: "#101012"
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                radius: 15
                color: "transparent"
                border.color: index === AIManager.activeSessionIndex ? ThemeManager.accentColor : ThemeManager.outlineStrongColor
                border.width: 1
                Behavior on border.color {
                    ColorAnimation { duration: 150 }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: AIManager.switchSession(index)
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 12
                spacing: 12

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 3

                    StyledLabel {
                        text: name
                        type: "body"
                        font.pixelSize: 14
                        font.weight: index === AIManager.activeSessionIndex ? Font.DemiBold : Font.Medium
                        letterSpacing: -0.15
                        elideMode: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    StyledLabel {
                        text: date
                        type: "caption"
                        font.pixelSize: 10
                        opacity: 0.3
                    }
                }

                BaseButton {
                    width: 32
                    height: 32
                    cornerRadius: 16

                    onClicked: AIManager.deleteSession(index)

                    StyledLabel {
                        anchors.centerIn: parent
                        text: ThemeManager.iconTrash
                        type: "icon"
                        font.pixelSize: 12
                        opacity: parent.isHovered ? 1.0 : 0.3
                    }
                }
            }
        }

        footer: Item {
            width: historyList.width
            height: 48

            BaseButton {
                anchors.fill: parent
                cornerRadius: 16

                onClicked: AIManager.newSession()

                Rectangle {
                    anchors.fill: parent
                    radius: 16
                    color: parent.isHovered ? ThemeManager.accentColor : "#1c1c1e"
                    opacity: parent.isHovered ? 1.0 : 0.8
                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                }

                StyledLabel {
                    anchors.centerIn: parent
                    text: "+ New Chat"
                    type: "body"
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    customColor: parent.parent.isHovered ? "#111111" : ThemeManager.contentOnBackgroundColor
                }
            }
        }
    }
}
