import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.core
import qs.components.scrolling
import qs.components.filepicker
import qs.components.menus
import qs.editor
import qs.services.wallpaper.projects

Rectangle {
    id: root

    radius: Design.editorSectionRadius
    color: Qt.rgba(1, 1, 1, 0.045)
    border.width: 1
    border.color: Qt.rgba(1, 1, 1, 0.075)
    clip: true

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            spacing: 6

            Text {
                Layout.fillWidth: true
                text: "Media"
                color: Design.text
                font.family: Design.fontText
                font.pixelSize: 12
                font.weight: Font.DemiBold
            }

            Rectangle {
                implicitWidth: countLabel.implicitWidth + 12
                implicitHeight: 20
                radius: 7
                color: Qt.rgba(1, 1, 1, 0.06)
                Text {
                    id: countLabel
                    anchors.centerIn: parent
                    text: WallpaperEditorService.mediaItems.length
                    color: Design.textMuted
                    font.family: Design.fontMono
                    font.pixelSize: 9
                }
            }

            PickerButton {
                label: "Import"
                enabled: WallpaperProjectService.loaded
                    && !WallpaperEditorService.importBusy
                onActivated: WallpaperEditorService.openPicker()
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: list
                anchors.fill: parent
                anchors.rightMargin: 7
                model: WallpaperEditorService.mediaItems
                spacing: 4
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                reuseItems: true
                visible: count > 0

                ScrollBar.vertical: MinimalScrollBar {}
                SmoothScrollBehavior { target: list }

                delegate: EditorAssetRow {
                    id: assetRow
                    required property var modelData
                    width: ListView.view.width
                    asset: modelData
                    workspaceId: WallpaperEditorService.workspaceId
                    selected: WallpaperEditorService.selectedAssetId === asset.id
                    onActivated: WallpaperEditorService.selectAsset(asset.id)
                    onContextRequested: (localX, localY) => {
                        WallpaperEditorService.selectAsset(asset.id)
                        assetMenu.openFor(assetRow, localX, localY)
                    }
                }
            }

            Column {
                anchors.centerIn: parent
                width: Math.max(80, parent.width - 20)
                spacing: 6
                visible: list.count === 0

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: WallpaperEditorService.activeProject
                        ? "No media yet" : "Start with an import"
                    color: Design.text
                    font.family: Design.fontText
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                }
                Text {
                    width: parent.width
                    text: WallpaperEditorService.activeProject
                        ? "Import images, animations, or video."
                        : "Import media to create your first wallpaper project."
                    color: Design.textMuted
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    font.family: Design.fontText
                    font.pixelSize: 9
                }
            }
        }
    }

    ContextMenu {
        id: assetMenu
        actions: [{
            id: "remove-project",
            label: "Remove from project",
            destructive: true,
            enabled: WallpaperEditorService.selectedAsset !== null
                && !WallpaperEditorService.importBusy
        }]
        onActionTriggered: actionId => {
            if (actionId === "remove-project")
                WallpaperEditorService.removeSelectedAsset()
        }
    }
}
