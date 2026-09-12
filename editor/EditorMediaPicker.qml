import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components.filepicker
import qs.core
import qs.services.config
import qs.services.wallpaper.projects

Rectangle {
    id: root

    readonly property string importBusyLabel: {
        const phase = WallpaperEditorImportService.phase
        if (phase === "probing-sources") return "Inspecting…"
        if (phase === "preparing-workspace") return "Preparing…"
        if (phase === "copying-assets")
            return "Copying " + Math.round(
                WallpaperDraftCopyService.progress * 100) + "%"
        if (phase === "probing-embedded") return "Verifying…"
        if (phase === "committing-project") return "Finishing…"
        if (phase.indexOf("rolling-back") >= 0
                || phase.indexOf("cancell") >= 0
                || phase.indexOf("discarding") >= 0)
            return "Cancelling…"
        return "Working…"
    }

    color: Design.islandExpanded
    radius: Design.editorSectionRadius
    border.width: 1
    border.color: Design.glassStroke

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10

        Text {
            Layout.fillWidth: true
            text: "Import Media"
            color: Design.text
            font.family: Design.fontDisplay
            font.pixelSize: 15
            font.weight: Font.DemiBold
        }

        FilePicker {
            Layout.fillWidth: true
            Layout.fillHeight: true
            mode: "files"
            maximumSelection: 64
            initialPath: ConfigService.wallpaperDirectories.length > 0
                ? ConfigService.wallpaperDirectories[0]
                : (Quickshell.env("HOME") || "/")
            busy: WallpaperEditorService.importBusy
            busyLabel: root.importBusyLabel
            externalError: WallpaperEditorService.importBusy ? ""
                : WallpaperEditorService.importReport.error
            onAccepted: paths => WallpaperEditorService.requestImport(paths)
            onCanceled: WallpaperEditorService.cancelPicker()
        }
    }
}
