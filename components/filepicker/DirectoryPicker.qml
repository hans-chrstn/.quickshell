import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell
import qs.components
import qs.core

Item {
    id: root

    property string initialPath: Quickshell.env("HOME") || "/"
    property string currentPath: normalizedPath(initialPath)
    property bool showHidden: false
    signal accepted(string path)
    signal canceled()

    function normalizedPath(value) {
        let path = String(value || "").trim()
        if (path.startsWith("file://"))
            path = decodeURIComponent(path.slice(7))
        path = path.replace(/\/+$/, "")
        return path.length > 0 ? path : "/"
    }

    function parentPath() {
        if (currentPath === "/")
            return "/"
        const separator = currentPath.lastIndexOf("/")
        return separator <= 0 ? "/" : currentPath.slice(0, separator)
    }

    function enter(path) {
        currentPath = normalizedPath(path)
    }

    FolderListModel {
        id: folders
        folder: "file://" + root.currentPath
        showDirs: true
        showFiles: false
        showDotAndDotDot: false
        showHidden: root.showHidden
        sortField: FolderListModel.Name
        sortReversed: false
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                Layout.preferredWidth: 30
                Layout.preferredHeight: 30
                radius: 10
                color: upHover.hovered ? Design.surfaceRaised : Design.surface
                border.width: 1
                border.color: Design.separator
                enabled: root.currentPath !== "/"
                opacity: enabled ? 1 : 0.4

                IslandGlyph {
                    anchors.centerIn: parent
                    name: "chevronLeft"
                    glyphColor: Design.textMuted
                }

                HoverHandler { id: upHover }
                TapHandler {
                    acceptedButtons: Qt.LeftButton
                    onTapped: root.enter(root.parentPath())
                }
            }

            Text {
                Layout.fillWidth: true
                text: root.currentPath
                elide: Text.ElideMiddle
                color: Design.text
                font.family: Design.fontMono
                font.pixelSize: 10
            }

            PickerButton {
                label: root.showHidden ? "Hide Hidden" : "Show Hidden"
                onActivated: root.showHidden = !root.showHidden
            }
        }

        ListView {
            id: folderList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 5
            model: folders
            boundsBehavior: Flickable.StopAtBounds

            delegate: Rectangle {
                id: folderRow
                required property string fileName
                required property url fileUrl
                width: folderList.width
                height: 38
                radius: 10
                color: rowHover.hovered ? Design.surfaceRaised : Design.surface
                border.width: 1
                border.color: rowHover.hovered
                    ? Design.glassHighlight : Design.separator

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 10
                    spacing: 10

                    IslandGlyph {
                        name: "folder"
                        glyphColor: rowHover.hovered ? Design.blue : Design.textMuted
                    }

                    Text {
                        Layout.fillWidth: true
                        text: folderRow.fileName
                        elide: Text.ElideRight
                        color: Design.text
                        font.family: Design.fontText
                        font.pixelSize: 11
                    }

                    IslandGlyph {
                        name: "chevronRight"
                        glyphColor: Design.textMuted
                        Layout.preferredWidth: 17
                        Layout.preferredHeight: 17
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                    }
                }

                HoverHandler { id: rowHover }
                TapHandler {
                    acceptedButtons: Qt.LeftButton
                    onTapped: root.enter(folderRow.fileUrl)
                }
            }

            Text {
                anchors.centerIn: parent
                visible: folders.status === FolderListModel.Ready
                    && folders.count === 0
                text: "No folders here"
                color: Design.textMuted
                font.family: Design.fontText
                font.pixelSize: 11
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Item { Layout.fillWidth: true }

            PickerButton {
                label: "Cancel"
                onActivated: root.canceled()
            }

            PickerButton {
                label: "Use This Folder"
                primary: true
                onActivated: root.accepted(root.currentPath)
            }
        }
    }
}
