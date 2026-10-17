import QtQuick
import QtQuick.Layouts
import qs.components.filepicker
import qs.core
import qs.services.wallpaper.projects

Rectangle {
    color: Theme.islandExpanded
    radius: Design.editorSectionRadius
    border.width: 1
    border.color: Theme.glassStroke

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            Text {
                Layout.fillWidth: true
                text: "Open Project"
                color: Theme.textPrimary
                font.family: Design.fontDisplay
                font.pixelSize: 15
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: "Choose a saved wallpaper project folder."
                color: Theme.textSecondary
                font.family: Design.fontText
                font.pixelSize: 10
                elide: Text.ElideRight
            }
        }

        FilePicker {
            Layout.fillWidth: true
            Layout.fillHeight: true
            mode: "directory"
            initialPath: WallpaperEditorOpenService.initialPath
            busy: WallpaperEditorOpenService.busy
            busyLabel: busy ? "Inspecting " + Math.round(WallpaperEditorOpenService.progress * 100) + "%" : "Inspecting…"
            externalError: WallpaperEditorOpenService.error
            onAccepted: paths => WallpaperEditorOpenService.choose(paths[0])
            onCanceled: WallpaperEditorOpenService.cancelPicker()
        }
    }
}
