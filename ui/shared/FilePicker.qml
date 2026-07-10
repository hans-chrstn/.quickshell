import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.core
import qs.ui.shared

Item {
    id: root

    property bool active: false

    signal fileSelected(string path)

    opacity: active ? 1 : 0
    visible: opacity > 0.01
    Behavior on opacity { NumberAnimation { duration: 150 } }

    onActiveChanged: {
        if (active) {
            FileBrowserManager.filterMode = "all"
        }
    }

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
            border.color: ThemeManager.outlineStrongColor
            border.width: 1
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                BaseButton {
                    width: 28
                    height: 28
                    cornerRadius: 14

                    onClicked: {
                        root.active = false
                    }

                    StyledLabel {
                        anchors.centerIn: parent
                        text: ThemeManager.iconClose
                        type: "icon"
                        font.pixelSize: 12
                        opacity: parent.isHovered ? 1.0 : 0.4
                    }
                }

                StyledLabel {
                    text: FileBrowserManager.currentPath.split("/").pop() || "Home"
                    type: "body"
                    font.weight: Font.DemiBold
                    font.pixelSize: 13
                    elideMode: Text.ElideRight
                    Layout.fillWidth: true
                }

                BaseButton {
                    width: 28
                    height: 28
                    cornerRadius: 14

                    onClicked: FileBrowserManager.navigateToParent()

                    StyledLabel {
                        anchors.centerIn: parent
                        text: "󰁝"
                        type: "icon"
                        font.pixelSize: 12
                        opacity: parent.isHovered ? 1.0 : 0.4
                    }
                }
            }

            ListView {
                id: fileList
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 2
                clip: true
                model: FileBrowserManager.fileModel

                delegate: BaseButton {
                    width: fileList.width
                    height: 38
                    cornerRadius: 8

                    onClicked: {
                        if (isDir) {
                            FileBrowserManager.navigateToPath(path)
                        } else {
                            root.fileSelected(path)
                            root.active = false
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: 8
                        color: parent.isHovered ? "#25282e" : "transparent"
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 10

                        StyledLabel {
                            text: isDir ? ThemeManager.iconFolder : (isImage ? ThemeManager.iconImage : ThemeManager.iconFile)
                            type: "icon"
                            font.pixelSize: 14
                            opacity: isImage ? 0.7 : 0.4
                        }

                        StyledLabel {
                            text: name
                            type: "body"
                            font.pixelSize: 13
                            font.weight: isDir ? Font.DemiBold : Font.Medium
                            elideMode: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                }
            }
        }
}
