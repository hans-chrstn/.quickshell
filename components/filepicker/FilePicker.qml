import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell
import qs.components
import qs.components.filepicker
import qs.components.scrolling
import qs.core
import qs.components.media
import qs.services.wallpaper

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
    readonly property string errorText: externalError.length > 0 ? externalError : internalError
    property bool busy: false
    property string busyLabel: "Working…"
    readonly property bool directoryMode: mode === "directory"
    readonly property bool wallpaperMode: mode === "wallpaper"
    signal accepted(var paths)
    signal canceled

    function normalizedPath(value) {
        let path = String(value || "").trim();
        if (path.startsWith("file://")) {
            try {
                path = decodeURIComponent(path.slice(7));
            } catch (exception) {
                return "/";
            }
        }
        path = path.replace(/\/+$/, "");
        return path.length > 0 ? path : "/";
    }

    function parentPath() {
        if (currentPath === "/")
            return "/";
        const separator = currentPath.lastIndexOf("/");
        return separator <= 0 ? "/" : currentPath.slice(0, separator);
    }

    function enter(path) {
        currentPath = normalizedPath(path);
        internalError = "";
    }

    function selected(path) {
        return selectedPaths.indexOf(path) >= 0;
    }

    function toggle(path) {
        const normalized = normalizedPath(path);
        const index = selectedPaths.indexOf(normalized);
        if (index >= 0) {
            const next = selectedPaths.slice();
            next.splice(index, 1);
            selectedPaths = next;
            internalError = "";
            return;
        }
        if (selectedPaths.length >= maximumSelection) {
            internalError = "Select up to " + maximumSelection + " files at once";
            return;
        }
        selectedPaths = selectedPaths.concat([normalized]);
        internalError = "";
    }

    function acceptCurrent() {
        if (busy)
            return;
        if (directoryMode) {
            accepted([currentPath]);
            return;
        }
        if (selectedPaths.length === 0) {
            internalError = "Select at least one file";
            return;
        }
        accepted(selectedPaths.slice());
    }

    FolderListModel {
        id: entries
        folder: LocalUrl.fromPath(root.currentPath)
        showDirs: true
        showFiles: !root.directoryMode
        showDotAndDotDot: false
        showHidden: root.showHidden
        nameFilters: root.wallpaperMode ? WallpaperCatalogService.candidateExtensions.map(extension => "*." + extension) : []
        sortField: FolderListModel.Name
        sortReversed: false
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            GlyphButton {
                Layout.preferredWidth: 30
                Layout.preferredHeight: 30
                glyph: "chevronLeft"
                accessibleName: "Go to parent folder"
                enabled: root.currentPath !== "/"
                opacity: enabled ? 1 : 0.4
                onActivated: root.enter(root.parentPath())
            }

            Text {
                Layout.fillWidth: true
                text: root.currentPath
                elide: Text.ElideMiddle
                color: Theme.textPrimary
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

            SmoothScrollBehavior {
                target: entryList
            }
            ScrollEdgeFeedback {
                target: entryList
            }

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
                    readonly property bool chosen: !fileIsDir && root.selected(path)
                    readonly property var media: root.wallpaperMode && !fileIsDir ? WallpaperProbeService.recordFor(path) : null
                    readonly property bool selectableMedia: !root.wallpaperMode || fileIsDir || (media?.state === "ready" ? WallpaperRenderSupportService.supported(media) : WallpaperCatalogService.isSupported(path))
                    width: Math.max(0, entryList.width - 10)
                    height: 38
                    radius: 10
                    color: chosen ? Theme.tint(Theme.accent) : rowHover.hovered ? Theme.fillElevated : Theme.fillSubtle
                    border.width: 1
                    border.color: chosen ? Theme.accent : rowHover.hovered ? Theme.glassHighlight : Theme.separator
                    opacity: selectableMedia ? 1 : 0.45

                    Component.onCompleted: if (root.wallpaperMode && !fileIsDir)
                        WallpaperProbeService.enqueue(path)

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 10
                        spacing: 10

                        Item {
                            Layout.preferredWidth: root.wallpaperMode && !entryRow.fileIsDir ? 34 : 17
                            Layout.preferredHeight: root.wallpaperMode && !entryRow.fileIsDir ? 30 : 17

                            Image {
                                anchors.fill: parent
                                visible: root.wallpaperMode && !entryRow.fileIsDir && WallpaperCatalogService.isSupported(entryRow.path)
                                source: visible ? LocalUrl.fromPath(entryRow.path) : ""
                                sourceSize.width: 68
                                sourceSize.height: 60
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                clip: true
                            }

                            MediaThumbnail {
                                anchors.fill: parent
                                visible: root.wallpaperMode && !entryRow.fileIsDir && !WallpaperCatalogService.isSupported(entryRow.path)
                                record: entryRow.media
                                cornerRadius: Design.space4
                            }

                            IslandGlyph {
                                anchors.centerIn: parent
                                visible: !root.wallpaperMode || entryRow.fileIsDir
                                name: entryRow.fileIsDir ? "folder" : "document"
                                glyphColor: entryRow.chosen || rowHover.hovered ? Theme.accent : Theme.textSecondary
                            }
                        }
                        Text {
                            Layout.fillWidth: true
                            text: entryRow.fileName
                            elide: Text.ElideRight
                            color: Theme.textPrimary
                            font.family: Design.fontText
                            font.pixelSize: 11
                        }
                        IslandGlyph {
                            visible: entryRow.fileIsDir
                            name: "chevronRight"
                            glyphColor: Theme.textSecondary
                            Layout.preferredWidth: 17
                            Layout.preferredHeight: 17
                        }
                        Text {
                            visible: entryRow.chosen
                            text: "✓"
                            color: Theme.accent
                            font.pixelSize: 12
                            font.weight: Font.Bold
                        }
                    }

                    HoverHandler {
                        id: rowHover
                    }
                    TapHandler {
                        onTapped: if (entryRow.fileIsDir)
                            root.enter(entryRow.path)
                        else if (entryRow.selectableMedia)
                            root.toggle(entryRow.path)
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: entries.status === FolderListModel.Ready && entries.count === 0
                    text: root.directoryMode ? "No folders here" : "No files here"
                    color: Theme.textSecondary
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
                text: root.errorText.length > 0 ? root.errorText : root.directoryMode ? "" : root.wallpaperMode ? root.selectedPaths.length > 0 ? "1 wallpaper selected" : "" : root.selectedPaths.length + " selected"
                color: root.errorText.length > 0 ? Theme.danger : Theme.textSecondary
                elide: Text.ElideRight
                font.family: Design.fontText
                font.pixelSize: 9
            }
            PickerButton {
                label: "Cancel"
                onActivated: root.canceled()
            }
            PickerButton {
                label: root.directoryMode ? "Use This Folder" : root.wallpaperMode ? "Use Wallpaper" : root.busy ? root.busyLabel : root.selectedPaths.length > 0 ? "Import " + root.selectedPaths.length : "Import"
                primary: true
                enabled: !root.busy && (!root.wallpaperMode || root.selectedPaths.length > 0)
                onActivated: root.acceptCurrent()
            }
        }
    }
}
