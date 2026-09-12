import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell
import qs.components
import qs.components.filepicker
import qs.components.scrolling
import qs.core

Item {
    id: root

    property string mode: "files"
    property string initialPath: Quickshell.env("HOME") || "/"
    property string currentPath: normalizedPath(initialPath)
    property bool showHidden: false
    property int maximumSelection: 64
    property var selectedPaths: []
    property string externalError: ""
    property string internalError: ""
    readonly property string errorText: externalError.length > 0
        ? externalError : internalError
    property bool busy: false
    property string busyLabel: "Working…"
    readonly property bool directoryMode: mode === "directory"
    signal accepted(var paths)
    signal canceled()

    function normalizedPath(value) {
        let path = String(value || "").trim()
        if (path.startsWith("file://")) {
            try { path = decodeURIComponent(path.slice(7)) }
            catch (exception) { return "/" }
        }
        path = path.replace(/\/+$/, "")
        return path.length > 0 ? path : "/"
    }

    function parentPath() {
        if (currentPath === "/") return "/"
        const separator = currentPath.lastIndexOf("/")
        return separator <= 0 ? "/" : currentPath.slice(0, separator)
    }

    function enter(path) {
        currentPath = normalizedPath(path)
        internalError = ""
    }

    function selected(path) {
        return selectedPaths.indexOf(path) >= 0
    }

    function toggle(path) {
        const normalized = normalizedPath(path)
        const index = selectedPaths.indexOf(normalized)
        if (index >= 0) {
            const next = selectedPaths.slice()
            next.splice(index, 1)
            selectedPaths = next
            internalError = ""
            return
        }
        if (selectedPaths.length >= maximumSelection) {
            internalError = "Select up to " + maximumSelection + " files at once"
            return
        }
        selectedPaths = selectedPaths.concat([normalized])
        internalError = ""
    }

    function acceptCurrent() {
        if (busy) return
        if (directoryMode) {
            accepted([currentPath])
            return
        }
        if (selectedPaths.length === 0) {
            internalError = "Select at least one file"
            return
        }
        accepted(selectedPaths.slice())
    }

    FolderListModel {
        id: entries
        folder: LocalUrl.fromPath(root.currentPath)
        showDirs: true
        showFiles: !root.directoryMode
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
                TapHandler { onTapped: root.enter(root.parentPath()) }
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

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            SmoothScrollBehavior { target: entryList }
            ScrollEdgeFeedback { target: entryList }

            ListView {
                id: entryList
                anchors.fill: parent
                clip: true
                spacing: 5
                model: entries
                boundsBehavior: Flickable.StopAtBounds
                reuseItems: true
                ScrollBar.vertical: MinimalScrollBar {}

                delegate: Rectangle {
                    id: entryRow
                    required property string fileName
                    required property url fileUrl
                    required property bool fileIsDir
                    readonly property string path: root.normalizedPath(fileUrl)
                    readonly property bool chosen: !fileIsDir
                        && root.selected(path)
                    width: Math.max(0, entryList.width - 10)
                    height: 38
                    radius: 10
                    color: chosen ? Qt.rgba(
                        Design.blue.r, Design.blue.g, Design.blue.b, 0.16)
                        : rowHover.hovered ? Design.surfaceRaised : Design.surface
                    border.width: 1
                    border.color: chosen ? Design.blue
                        : rowHover.hovered ? Design.glassHighlight
                        : Design.separator

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 10
                        spacing: 10

                        IslandGlyph {
                            name: entryRow.fileIsDir ? "folder" : "document"
                            glyphColor: entryRow.chosen || rowHover.hovered
                                ? Design.blue : Design.textMuted
                        }
                        Text {
                            Layout.fillWidth: true
                            text: entryRow.fileName
                            elide: Text.ElideRight
                            color: Design.text
                            font.family: Design.fontText
                            font.pixelSize: 11
                        }
                        IslandGlyph {
                            visible: entryRow.fileIsDir
                            name: "chevronRight"
                            glyphColor: Design.textMuted
                            Layout.preferredWidth: 17
                            Layout.preferredHeight: 17
                        }
                        Text {
                            visible: entryRow.chosen
                            text: "✓"
                            color: Design.blue
                            font.pixelSize: 12
                            font.weight: Font.Bold
                        }
                    }

                    HoverHandler { id: rowHover }
                    TapHandler {
                        onTapped: entryRow.fileIsDir
                            ? root.enter(entryRow.path) : root.toggle(entryRow.path)
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: entries.status === FolderListModel.Ready
                        && entries.count === 0
                    text: root.directoryMode ? "No folders here" : "No files here"
                    color: Design.textMuted
                    font.family: Design.fontText
                    font.pixelSize: 11
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                Layout.fillWidth: true
                text: root.errorText.length > 0 ? root.errorText
                    : root.directoryMode ? ""
                    : root.selectedPaths.length + " selected"
                color: root.errorText.length > 0 ? Design.red : Design.textMuted
                elide: Text.ElideRight
                font.family: Design.fontText
                font.pixelSize: 9
            }
            PickerButton { label: "Cancel"; onActivated: root.canceled() }
            PickerButton {
                label: root.directoryMode ? "Use This Folder"
                    : root.busy ? root.busyLabel
                    : root.selectedPaths.length > 0
                        ? "Import " + root.selectedPaths.length : "Import"
                primary: true
                enabled: !root.busy
                onActivated: root.acceptCurrent()
            }
        }
    }
}
